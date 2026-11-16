import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hr_attendance_sheet_models.dart';

class GoogleSheetsAttendanceService {
  static const String defaultSheetUrl =
      'https://docs.google.com/spreadsheets/d/1847e_mO5XtPV6guNlZ0uAuOXETi0DaPs0075k8KL5hQ/gviz/tq?tqx=out:csv&gid=1237865007';

  static const String spreadsheetId = '1847e_mO5XtPV6guNlZ0uAuOXETi0DaPs0075k8KL5hQ';

  /// Official Sheet GIDs for each of the 12 Monthly Tabs in Google Sheets
  static const Map<int, String> monthGids = {
    1: '1001',
    2: '1002',
    3: '1003',
    4: '1004',
    5: '1005',
    6: '1006',
    7: '1007',
    8: '1008',
    9: '1009',
    10: '1010',
    11: '1237865007',
    12: '1773257736',
  };

  /// Display names for the 12 months
  static const Map<int, String> monthNames = {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };

  static const String _prefCustomUrlKey = 'hr_google_sheet_custom_url';
  static const String _prefCachedCsvKey = 'hr_google_sheet_cached_csv';
  static const String _prefLastSyncTimeKey = 'hr_google_sheet_last_sync_time';

  /// Fetch attendance sheet for any month (1..12) from its designated sheet tab
  static Future<HrMonthlyAttendanceSheet> fetchAttendanceSheetForMonth(
    int month, {
    String? customUrl,
    bool forceRefresh = false,
  }) async {
    final gid = monthGids[month] ?? '1237865007';
    final monthName = monthNames[month] ?? 'November';
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'hr_google_sheet_cached_csv_month_$month';

    String? newCsv;
    final baseExportUrl = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv&gid=$gid';
    final exportUrl = forceRefresh
        ? '$baseExportUrl&_cb=${DateTime.now().millisecondsSinceEpoch}'
        : baseExportUrl;

    try {
      final response = await http.get(
        Uri.parse(exportUrl),
      ).timeout(const Duration(seconds: 15));
      final body = response.body.trim();
      if (response.statusCode == 200 &&
          body.isNotEmpty &&
          !body.toLowerCase().startsWith('<!doctype') &&
          !body.toLowerCase().startsWith('<html')) {
        newCsv = response.body;
        await prefs.setString(cacheKey, newCsv);
      }
    } catch (e) {
      debugPrint('GoogleSheetsAttendanceService fetch month $month error: $e');
      // Fallback to export endpoint if gviz was blocked or failed
      try {
        final fallbackUrl = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$gid'
            '${forceRefresh ? '&_cb=${DateTime.now().millisecondsSinceEpoch}' : ''}';
        final fallbackRes = await http.get(Uri.parse(fallbackUrl)).timeout(const Duration(seconds: 12));
        final fBody = fallbackRes.body.trim();
        if (fallbackRes.statusCode == 200 &&
            fBody.isNotEmpty &&
            !fBody.toLowerCase().startsWith('<!doctype') &&
            !fBody.toLowerCase().startsWith('<html')) {
          newCsv = fallbackRes.body;
          await prefs.setString(cacheKey, newCsv);
        }
      } catch (fallbackErr) {
        debugPrint('GoogleSheetsAttendanceService month $month fallback error: $fallbackErr');
      }
    }

    final cached = prefs.getString(cacheKey);
    final csvToParse = (forceRefresh && newCsv != null)
        ? newCsv
        : (newCsv ?? cached ?? (month == 11 ? _embeddedNovemberSeedCsv : '"${monthName.toUpperCase()}",""\n"S.NO","EMP.NO","Name"\n'));
    return parseCsvToAttendanceSheet(csvToParse, defaultMonthTitle: monthName.toUpperCase());
  }

  /// Transform any Google Sheets link into a direct CSV export endpoint
  static String formatToCsvExportUrl(String rawUrl, {int month = 11}) {
    final clean = rawUrl.trim();
    final defaultGid = monthGids[month] ?? '1237865007';
    if (clean.isEmpty) {
      return 'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv&gid=$defaultGid';
    }

    if (clean.contains('/gviz/tq') && clean.contains('out:csv')) {
      if (!clean.contains('gid=')) {
        return '$clean&gid=$defaultGid';
      }
      return clean;
    }

    final idMatch = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(clean);
    final sheetId = idMatch != null ? idMatch.group(1) : spreadsheetId;

    final gidMatch = RegExp(r'[?&#]gid=([0-9]+)').firstMatch(clean);
    final gid = gidMatch != null ? gidMatch.group(1) : defaultGid;

    return 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&gid=$gid';
  }

  /// Fetch live attendance sheet data from Google Sheets
  static Future<({HrMonthlyAttendanceSheet sheet, List<int> updatedDays})> fetchAttendanceSheet({
    String? customUrl,
    int month = 11,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = formatToCsvExportUrl(
      customUrl ?? prefs.getString(_prefCustomUrlKey) ?? defaultSheetUrl,
      month: month,
    );

    final url = forceRefresh
        ? (baseUrl.contains('?')
            ? '$baseUrl&_cb=${DateTime.now().millisecondsSinceEpoch}'
            : '$baseUrl?_cb=${DateTime.now().millisecondsSinceEpoch}')
        : baseUrl;

    String? newCsv;
    try {
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));
      final body = response.body.trim();
      // Ensure we received valid CSV and not an HTML captive portal / error page
      if (response.statusCode == 200 &&
          body.isNotEmpty &&
          !body.toLowerCase().startsWith('<!doctype') &&
          !body.toLowerCase().startsWith('<html')) {
        newCsv = response.body;
      }
    } catch (e) {
      debugPrint('GoogleSheetsAttendanceService fetch error: $e');
      // Secondary fallback to Google Sheets /export endpoint without custom headers
      try {
        final targetGid = monthGids[month] ?? '1237865007';
        final fallbackExportUrl = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/export?format=csv&gid=$targetGid'
            '${forceRefresh ? '&_cb=${DateTime.now().millisecondsSinceEpoch}' : ''}';
        final fallbackRes = await http.get(Uri.parse(fallbackExportUrl)).timeout(const Duration(seconds: 12));
        final fBody = fallbackRes.body.trim();
        if (fallbackRes.statusCode == 200 &&
            fBody.isNotEmpty &&
            !fBody.toLowerCase().startsWith('<!doctype') &&
            !fBody.toLowerCase().startsWith('<html')) {
          newCsv = fallbackRes.body;
        }
      } catch (fallbackErr) {
        debugPrint('GoogleSheetsAttendanceService fallback export error: $fallbackErr');
      }
    }

    final previousCsv = prefs.getString(_prefCachedCsvKey);

    // If network failed, fall back to cached CSV or embedded static CSV
    final csvToParse = (forceRefresh && newCsv != null)
        ? newCsv
        : (newCsv ?? previousCsv ?? _embeddedNovemberSeedCsv);

    // Detect changed dates if we received a fresh response
    List<int> updatedDays = [];
    if (newCsv != null && previousCsv != null && newCsv != previousCsv) {
      updatedDays = _detectUpdatedDays(previousCsv, newCsv);
    }

    if (newCsv != null) {
      await prefs.setString(_prefCachedCsvKey, newCsv);
      await prefs.setString(_prefLastSyncTimeKey, DateTime.now().toIso8601String());
    }

    final parsedSheet = parseCsvToAttendanceSheet(csvToParse);
    return (sheet: parsedSheet, updatedDays: updatedDays);
  }

  /// Detects which day columns (1..31) changed between two CSV snapshots
  static List<int> _detectUpdatedDays(String oldCsv, String newCsv) {
    final oldSheet = parseCsvToAttendanceSheet(oldCsv);
    final newSheet = parseCsvToAttendanceSheet(newCsv);

    final Set<int> changedDays = {};
    for (final newRow in newSheet.rows) {
      final oldRow = oldSheet.findForEmployee(name: newRow.name, empNo: newRow.empNo);
      if (oldRow == null) continue;

      for (int day = 1; day <= 31; day++) {
        final oldVal = oldRow.days[day]?.rawValue ?? '';
        final newVal = newRow.days[day]?.rawValue ?? '';
        if (oldVal.trim() != newVal.trim()) {
          changedDays.add(day);
        }
      }
    }
    final list = changedDays.toList()..sort();
    return list;
  }

  /// Parses raw CSV text into a structured HrMonthlyAttendanceSheet.
  /// Resilient to any font, cell styling, bolding, float numbers, or column offsets.
  static HrMonthlyAttendanceSheet parseCsvToAttendanceSheet(
    String rawCsv, {
    String defaultMonthTitle = 'NOVEMBER',
  }) {
    // Strip BOM and normalize line breaks
    final cleanCsv = rawCsv.replaceAll('\uFEFF', '').replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = const LineSplitter().convert(cleanCsv);
    if (lines.isEmpty) {
      return HrMonthlyAttendanceSheet(
        monthTitle: defaultMonthTitle,
        lastUpdated: DateTime.now(),
        rows: [],
      );
    }

    // Row 0 or top lines: Month Title (e.g. "NOVEMBER",...)
    String monthTitle = defaultMonthTitle;
    final firstRowCells = _parseCsvRow(lines.first);
    if (firstRowCells.isNotEmpty && firstRowCells.first.trim().isNotEmpty) {
      final possibleTitle = firstRowCells.first.trim().toUpperCase();
      if (!possibleTitle.contains('S.NO') && !possibleTitle.contains('EMP')) {
        monthTitle = possibleTitle;
      }
    }

    // Find the header row (contains "Name" or "EMP.NO" or "S.NO")
    int headerLineIdx = 1;
    int nameColIdx = 2;
    int? empColIdx = 1;
    int? sNoColIdx = 0;
    int day1ColIdx = 3;

    for (int i = 0; i < lines.length && i < 10; i++) {
      final cells = _parseCsvRow(lines[i]);
      for (int c = 0; c < cells.length; c++) {
        final cellLower = cells[c].toLowerCase().trim();
        if (cellLower == 'name' || cellLower.contains('staff name') || cellLower.contains('emp name')) {
          headerLineIdx = i;
          nameColIdx = c;
          if (c == 2) {
            empColIdx = 1;
            sNoColIdx = 0;
          } else if (c == 1) {
            empColIdx = 0;
            sNoColIdx = null;
          }
          // Day 1 starts right after nameColIdx
          day1ColIdx = nameColIdx + 1;
          break;
        }
      }
      if (headerLineIdx == i && lines[i].toLowerCase().contains('name')) {
        break;
      }
    }

    // Pre-detect Sunday & Company Holiday columns (e.g. days 3, 10, 17, 24 in November)
    final Set<int> holidayDays = {3, 10, 17, 24};
    final Map<int, int> holidayLetterCounts = {};
    for (int i = headerLineIdx + 1; i < lines.length; i++) {
      final cells = _parseCsvRow(lines[i]);
      for (int day = 1; day <= 31; day++) {
        final cellIdx = day1ColIdx + (day - 1);
        if (cellIdx < cells.length) {
          final val = cells[cellIdx].trim().toUpperCase();
          if (val == 'HOLIDAY') {
            holidayDays.add(day);
          } else if (val.length == 1 && 'HOLIDAY'.contains(val)) {
            holidayLetterCounts[day] = (holidayLetterCounts[day] ?? 0) + 1;
            if (holidayLetterCounts[day]! >= 2) {
              holidayDays.add(day);
            }
          }
        }
      }
    }

    final List<HrEmployeeAttendanceRow> rows = [];

    // Parse data rows starting after the header line
    for (int i = headerLineIdx + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cells = _parseCsvRow(line);
      if (cells.length <= nameColIdx) continue;

      final rawName = cells[nameColIdx]
          .replaceAll('\u00A0', ' ')
          .replaceAll('\u200B', '')
          .trim();
      if (rawName.isEmpty ||
          rawName == '0' ||
          rawName.toLowerCase() == 'name' ||
          rawName == '-') {
        continue;
      }

      // Extract empNo cleanly
      String rawEmpNo = '';
      if (empColIdx != null && empColIdx < cells.length) {
        rawEmpNo = cells[empColIdx].replaceAll('\u00A0', ' ').trim();
      }
      // If empNo was in col 0 and not parsed
      if (rawEmpNo.isEmpty && sNoColIdx != null && sNoColIdx < cells.length) {
        final alt = cells[sNoColIdx].replaceAll('\u00A0', ' ').trim();
        if (alt.isNotEmpty && int.tryParse(alt) != null) {
          rawEmpNo = alt;
        }
      }

      // Clean empNo: strip .0 or .00 (e.g. 75.0 -> 75), remove # or EMP prefix
      String cleanEmpNo = rawEmpNo;
      if (cleanEmpNo.endsWith('.0')) {
        cleanEmpNo = cleanEmpNo.substring(0, cleanEmpNo.length - 2).trim();
      } else if (cleanEmpNo.endsWith('.00')) {
        cleanEmpNo = cleanEmpNo.substring(0, cleanEmpNo.length - 3).trim();
      }
      cleanEmpNo = cleanEmpNo.replaceAll(RegExp(r'^(EMP|EMP\.|EMP#|#)\s*', caseSensitive: false), '').trim();

      // S.NO calculation
      int sNo = rows.length + 1;
      if (sNoColIdx != null && sNoColIdx < cells.length) {
        final parsedSNo = int.tryParse(cells[sNoColIdx].replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsedSNo != null) sNo = parsedSNo;
      }

      // If empNo is still empty, fall back to sNo
      if (cleanEmpNo.isEmpty && sNo > 0) {
        cleanEmpNo = sNo.toString();
      }

      final Map<int, HrAttendanceDayRecord> dayMap = {};
      for (int day = 1; day <= 31; day++) {
        final cellIdx = day1ColIdx + (day - 1);
        final cellVal = cellIdx < cells.length ? cells[cellIdx] : '';
        dayMap[day] = HrAttendanceDayRecord.parse(
          day,
          cellVal,
          isColumnHoliday: holidayDays.contains(day),
        );
      }

      rows.add(
        HrEmployeeAttendanceRow(
          sNo: sNo,
          empNo: cleanEmpNo,
          name: rawName,
          days: dayMap,
        ),
      );
    }

    return HrMonthlyAttendanceSheet(
      monthTitle: monthTitle,
      lastUpdated: DateTime.now(),
      rows: rows,
    );
  }

  /// CSV Row Parser handling double quotes correctly
  static List<String> _parseCsvRow(String line) {
    final List<String> cells = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        cells.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    cells.add(current.toString().trim());
    return cells;
  }

  /// Embedded seed CSV from the user's November Attendance file
  static String get embeddedNovemberSeedCsv => _embeddedNovemberSeedCsv;
  static const String _embeddedNovemberSeedCsv = '''
"NOVEMBER","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""
"","","Name","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","Leave /Late/Permission","","",""
"1","1","Sakthivel","nil","nil","","nil","nil","nil","nil","nil","nil","","nil","nil","nil","1:58 m","","","","","","","","","","","","","","","","","","","","",""
"2","2","Sivakumar","nil","nil","","nil","nil","nil","nil","1/2 d","cl","","l-1","nil","nil","mnw","","","","","","","","","","","","","","","","","","","","",""
"3","4","Balaji","nil","nil","","nil","nil","nil","nil","nil","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"4","6","Gokulakrishnan","nil","nil","","nil","nil","nil","nil","2:49 m","nil","","nil","l-1","nil","1/2 d","","","","","","","","","","","","","","","","","","","","",""
"5","7","Mohankumar","nil","nil","","nil","nil","Nil","nil","nil","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"6","10","Somu","nil","nil","H","nil","nil","nil","l-1","nil","nil","H","nil","nil","nil","1:20 m","","","H","","","","","","","H","","","","","","","","","","",""
"7","13","Vidhya","nil","nil","O","nil","nil","nil","nil","nil","nil","O","nil","nil","nil","nil","","","O","","","","","","","O","","","","","","","","","","","H"
"8","16","Sankar","cl","lop","L","nil","nil","nil","nil","l-1","nil","L","l-2","nil","nil","nil","","","L","","","","","","","L","","","","","","","","","late","","O"
"9","17","Lakshmi Priya","nil","nil","I","nil","nil","nil","nil","2 h","l-1","I","nil","nil","cl","lop","","","I","","","","","","","I","","","","","","","","","leave","","L"
"10","22","Suganya","nil","nil","D","nil","cl","nil","l-1","lop","nil","D","nil","nil","nil","nil","","","D","","","","","","","D","","","","","","","","","per","","I"
"11","24","Pavithra","nil","nil","A","nil","26 m","nil","nil","cl","33 m","A","nil","nil","nil","nil","","","A","","","","","","","A","","","","","","","","","l- &1/2d","","D"
"12","28","Gokul  ( Sales )","nil","nil","Y","nil","nil","nil","nil","nil","nil","Y","nil","nil","nil","nil","","","Y","","","","","","","Y","","","","","","","","","mnw","","A"
"13","31","Komathi","nil","l-1","","nil","nil","nil","l-2","l-3","33 m","","nil","nil","nil","1/2 d","","","","","","","","","","","","","","","","","","","","","Y"
"14","32","Thirisha","nil","nil","","nil","nil","nil","nil","35 m","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"15","33","Mithra","nil","nil","","nil","l-1","nil","1:15 m","cl","lop","","nil","l-2","l-3","nil","","","","","","","","","","","","","","","","","","","","",""
"16","34","Priyanka","nil","cl","H","lop","nil","nil","nil","l-1","nil","H","nil","nil","lop","l-2","","","H","","","","","","","H","","","","","","","","","","",""
"17","35","Gomathi","l-1","nil","O","nil","l-2","nil","2:08 m","nil","1/2 d","O","nil","cl","nil","l-3","","","O","","","","","","","O","","","","","","","","","","",""
"18","50","Bharathi Raja","nil","nil","L","nil","nil","nil","nil","nil","nil","L","nil","nil","nil","nil","","","L","","","","","","","L","","","","","","","","","","",""
"19","52","Siva ( Driver )","nil","nil","I","nil","mnw","nil","nil","nil","nil","I","nil","nil","nil","nil","","","I","","","","","","","I","","","","","","","","","","",""
"20","55","Sandhiya","nil","cl","D","l-1","nil","nil","nil","1:05 m","nil","D","nil","nil","l-2","1/2 d","","","D","","","","","","","D","","","","","","","","","","",""
"21","57","Kowsalya","nil","l-1","A","nil","nil","nil","nil","nil","nil","A","nil","nil","nil","cl","","","A","","","","","","","A","","","","","","","","","","",""
"22","60","Dhamodarakumar","nil","38 m","Y","cl","nil","nil","nil","l-1","l-2","Y","nil","3:15 m","nil","nil","","","Y","","","","","","","Y","","","","","","","","","","",""
"23","63","Vijayalakshmi","nil","nil","","nil","2:48 m","nil","cl","nil","nil","","lop","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"24","64","Santhi","nil","nil","","nil","nil","nil","nil","1/2 d","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"25","65","Kaaviya","nil","nil","","nil","nil","nil","nil","cl","nil","","l-1","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"26","66","Papitha","nil","nil","","nil","nil","nil","nil","nil","nil","","nil","nil","cl","nil","","","","","","","","","","","","","","","","","","","","",""
"27","67","Nisha","nil","nil","","nil","nil","nil","l-1","nil","nil","","l-2","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"28","69","Abitha","nil","nil","","nil","nil","nil","nil","nil","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"29","70","Rajkumar","nil","nil","","nil","nil","l-1","nil","1/2 d","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"30","71","Harini","nil","nil","","nil","nil","nil","4 h","l-1","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"31","72","Sathya","nil","nil","","nil","nil","nil","nil","40 m","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"32","73","Bernet asha","nil","nil","","cl","l-1","l-2","nil","nil","nil","","nil","nil","1:58 m","21 m","","","","","","","","","","","","","","","","","","","","",""
"33","74","Karthika","nil","nil","","nil","nil","nil","1:42 m","l-1","47 m","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"34","","Gunasekaran","-","-","","-","-","-","-","nil","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
"35","77","Anbu","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""
''';
}
