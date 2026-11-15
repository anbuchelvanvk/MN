import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hr_attendance_sheet_models.dart';

class GoogleSheetsAttendanceService {
  static const String defaultSheetUrl =
      'https://docs.google.com/spreadsheets/d/1847e_mO5XtPV6guNlZ0uAuOXETi0DaPs0075k8KL5hQ/gviz/tq?tqx=out:csv';

  static const String _prefCustomUrlKey = 'hr_google_sheet_custom_url';
  static const String _prefCachedCsvKey = 'hr_google_sheet_cached_csv';
  static const String _prefLastSyncTimeKey = 'hr_google_sheet_last_sync_time';

  /// Transform any Google Sheets link into a direct CSV export endpoint
  static String formatToCsvExportUrl(String rawUrl) {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return defaultSheetUrl;

    if (clean.contains('/gviz/tq') && clean.contains('out:csv')) {
      return clean;
    }

    final idMatch = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(clean);
    if (idMatch != null) {
      final sheetId = idMatch.group(1);
      return 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv';
    }

    return clean;
  }

  /// Fetch live attendance sheet data from Google Sheets
  static Future<({HrMonthlyAttendanceSheet sheet, List<int> updatedDays})> fetchAttendanceSheet({
    String? customUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final url = formatToCsvExportUrl(customUrl ?? prefs.getString(_prefCustomUrlKey) ?? defaultSheetUrl);

    String? newCsv;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        newCsv = response.body;
      }
    } catch (e) {
      debugPrint('GoogleSheetsAttendanceService fetch error: $e');
    }

    final previousCsv = prefs.getString(_prefCachedCsvKey);

    // If network failed, fall back to cached CSV or embedded static CSV
    final csvToParse = newCsv ?? previousCsv ?? _embeddedNovemberSeedCsv;

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

  /// Parses raw CSV text into a structured HrMonthlyAttendanceSheet
  static HrMonthlyAttendanceSheet parseCsvToAttendanceSheet(String rawCsv) {
    final lines = const LineSplitter().convert(rawCsv);
    if (lines.isEmpty) {
      return HrMonthlyAttendanceSheet(
        monthTitle: 'NOVEMBER',
        lastUpdated: DateTime.now(),
        rows: [],
      );
    }

    // Row 0: Month Title (e.g. "NOVEMBER",...)
    String monthTitle = 'NOVEMBER';
    final firstRowCells = _parseCsvRow(lines.first);
    if (firstRowCells.isNotEmpty && firstRowCells.first.trim().isNotEmpty) {
      monthTitle = firstRowCells.first.trim().toUpperCase();
    }

    final List<HrEmployeeAttendanceRow> rows = [];

    // Rows 2+ contain staff records
    for (int i = 2; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cells = _parseCsvRow(line);
      if (cells.length < 3) continue;

      final sNoStr = cells[0].trim();
      final empNoStr = cells[1].trim();
      final nameStr = cells[2].trim();

      if (nameStr.isEmpty || nameStr == '0') continue;

      final sNo = int.tryParse(sNoStr) ?? (i - 1);
      final Map<int, HrAttendanceDayRecord> dayMap = {};

      // Day 1 corresponds to cells[3], Day 2 to cells[4]... up to Day 31 cells[33]
      for (int day = 1; day <= 31; day++) {
        final cellIdx = day + 2;
        final cellVal = cellIdx < cells.length ? cells[cellIdx] : '';
        dayMap[day] = HrAttendanceDayRecord.parse(day, cellVal);
      }

      rows.add(
        HrEmployeeAttendanceRow(
          sNo: sNo,
          empNo: empNoStr,
          name: nameStr,
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
"5","7","Mohankumar","nil","nil","","nil","nil","nil","nil","nil","nil","","nil","nil","nil","nil","","","","","","","","","","","","","","","","","","","","",""
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
''';
}
