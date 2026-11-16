import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hr_attendance_sheet_models.dart';
import '../models/profile_document_models.dart';
import '../providers/ecosystem_provider.dart';

class CeoExcelBackupService {
  /// Generates a comprehensive 8-sheet Excel backup workbook containing all organization datasets
  static Future<String> generateCompleteExcelBackup(EcosystemProvider eco) async {
    final excel = Excel.createExcel();

    // 1. Staff Directory Sheet
    final staffSheet = excel['Staff Directory'];
    staffSheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Full Name'),
      TextCellValue('Designation / Role'),
      TextCellValue('Role Hierarchy'),
      TextCellValue('Department'),
      TextCellValue('Mobile Phone'),
      TextCellValue('Official Email'),
      TextCellValue('Date of Birth'),
      TextCellValue('Gender'),
      TextCellValue('Relationship Status'),
      TextCellValue('Marriage Anniversary'),
    ]);
    for (final emp in eco.employees) {
      staffSheet.appendRow([
        TextCellValue(emp.id),
        TextCellValue(emp.name),
        TextCellValue(emp.role),
        TextCellValue(emp.roleType),
        TextCellValue(emp.dept),
        TextCellValue(emp.phone),
        TextCellValue(emp.email),
        TextCellValue(emp.dob),
        TextCellValue(emp.gender),
        TextCellValue(emp.relationshipStatus),
        TextCellValue(emp.anniversaryDate),
      ]);
    }

    // 2. Attendance Master Sheet
    final attendSheet = excel['Attendance Master'];
    attendSheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Staff Name'),
      TextCellValue('Date Label'),
      TextCellValue('Shift Status'),
      TextCellValue('Tuesday Overtime'),
      TextCellValue('Source'),
    ]);
    final hrSheet = eco.hrAttendanceSheet;
    final now = DateTime.now();
    for (final emp in eco.employees) {
      if (!emp.hasAttendanceAndGrooming) continue;
      final hrRow = hrSheet?.findForEmployee(name: emp.name, empNo: emp.empNo);
      for (int day = 1; day <= (hrSheet?.daysInMonth ?? 30); day++) {
        final rec = hrRow?.days[day];
        if (rec != null && rec.type != HrAttendanceDayType.pendingUpdate) {
          final isTue = DateTime(now.year, now.month, day).weekday == DateTime.tuesday;
          attendSheet.appendRow([
            TextCellValue(emp.id),
            TextCellValue(emp.name),
            TextCellValue('Day $day'),
            TextCellValue(rec.displayLabel),
            TextCellValue(isTue ? 'Yes (Overtime)' : 'No'),
            TextCellValue('HR Google Sheets Master Ledger'),
          ]);
        }
      }
    }

    // 3. Social Causes Sheet
    final socialSheet = excel['Social Causes'];
    socialSheet.appendRow([
      TextCellValue('Cause ID'),
      TextCellValue('Deed Title'),
      TextCellValue('Description'),
      TextCellValue('Submitted By'),
      TextCellValue('Category'),
      TextCellValue('Reactions / Likes'),
      TextCellValue('Timestamp'),
    ]);
    for (final cause in eco.socialCauses) {
      socialSheet.appendRow([
        TextCellValue(cause.id),
        TextCellValue(cause.title),
        TextCellValue(cause.description),
        TextCellValue(cause.employeeName),
        TextCellValue(cause.causeType),
        TextCellValue('${cause.likedEmpIds.length} Likes'),
        TextCellValue(cause.date.toIso8601String()),
      ]);
    }

    // 4. Company Notifications Sheet
    final notifSheet = excel['Notifications'];
    notifSheet.appendRow([
      TextCellValue('Notification ID'),
      TextCellValue('Title'),
      TextCellValue('Content'),
      TextCellValue('Notification Type'),
      TextCellValue('Sender'),
      TextCellValue('Target Employee ID'),
      TextCellValue('Timestamp'),
      TextCellValue('Action Tag'),
    ]);
    for (final notif in eco.companyNotifications) {
      notifSheet.appendRow([
        TextCellValue(notif.id),
        TextCellValue(notif.title),
        TextCellValue(notif.content),
        TextCellValue(notif.type.name),
        TextCellValue('${notif.senderName} (${notif.senderRole})'),
        TextCellValue(notif.targetEmpId ?? 'All Staff'),
        TextCellValue(notif.timestamp.toIso8601String()),
        TextCellValue(notif.actionTag ?? 'None'),
      ]);
    }

    // 5. Health Records Sheet
    final healthSheet = excel['Health Records'];
    healthSheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Staff Name'),
      TextCellValue('Current Weight (kg)'),
      TextCellValue('Height (cm)'),
      TextCellValue('Calculated BMI'),
      TextCellValue('Daily Calorie Intake Target'),
      TextCellValue('Step Goal'),
    ]);
    for (final emp in eco.employees) {
      healthSheet.appendRow([
        TextCellValue(emp.id),
        TextCellValue(emp.name),
        TextCellValue(eco.userWeightKg.toStringAsFixed(1)),
        TextCellValue(eco.userHeightCm.toStringAsFixed(1)),
        TextCellValue(eco.currentBmi.toStringAsFixed(1)),
        TextCellValue('${eco.dailyCalorieTarget.toInt()} kcal'),
        TextCellValue('${eco.dailyStepGoal} steps'),
      ]);
    }

    // 6. Document Vault Sheet
    final docSheet = excel['Document Vault'];
    docSheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Staff Name'),
      TextCellValue('Document Title'),
      TextCellValue('Document Category'),
      TextCellValue('Mandatory Requirement'),
      TextCellValue('Custody Verification Status'),
      TextCellValue('Date of Deposit'),
    ]);
    for (final emp in eco.employees) {
      final docs = eco.getEmployeeDocuments(emp.id);
      for (final doc in docs) {
        docSheet.appendRow([
          TextCellValue(emp.id),
          TextCellValue(emp.name),
          TextCellValue(doc.title),
          TextCellValue(doc.category),
          TextCellValue(doc.isMandatory ? 'Yes (Mandatory)' : 'Optional'),
          TextCellValue(doc.status == DocumentSubmissionStatus.submitted ? 'Verified & In Safe Custody' : 'Pending Submission'),
          TextCellValue(doc.submissionDate.isNotEmpty ? doc.submissionDate : 'Not Deposited'),
        ]);
      }
    }

    // 7. Grooming Audits Sheet
    final groomingSheet = excel['Grooming Audits'];
    groomingSheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Staff Name'),
      TextCellValue('Department'),
      TextCellValue('Daily Grooming Score (Max 50)'),
      TextCellValue('Inspection Compliance'),
    ]);
    for (final emp in eco.employees) {
      if (!emp.hasAttendanceAndGrooming) continue;
      final points = eco.getEmployeeGroomingDailyPoints(emp.id);
      groomingSheet.appendRow([
        TextCellValue(emp.id),
        TextCellValue(emp.name),
        TextCellValue(emp.dept),
        TextCellValue('$points / 50 Points'),
        TextCellValue(points >= 40 ? 'Fully Compliant (Star Groomed)' : 'Standard Grooming'),
      ]);
    }

    // 8. Operations Tasks Sheet
    final tasksSheet = excel['Operations Tasks'];
    tasksSheet.appendRow([
      TextCellValue('Task ID'),
      TextCellValue('Title'),
      TextCellValue('Assigned Employee ID'),
      TextCellValue('Priority'),
      TextCellValue('Status'),
      TextCellValue('Due Date / Time'),
    ]);
    for (final task in eco.operationsDeptTasks) {
      tasksSheet.appendRow([
        TextCellValue(task.id),
        TextCellValue(task.title),
        TextCellValue(task.empId),
        TextCellValue(task.priority),
        TextCellValue(task.status == 'completed' ? 'Completed' : 'Pending'),
        TextCellValue(task.due),
      ]);
    }

    // Remove default Sheet1 if present
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to generate Excel bytes');
    }

    Directory tempDir;
    try {
      tempDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      tempDir = Directory.systemTemp;
    }

    final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/MN_Jewel_Park_Full_Backup_$timestampStr.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    debugPrint('Excel backup generated successfully at: ${file.path} (${bytes.length} bytes)');
    return file.path;
  }

  /// Parses bytes from an uploaded Excel file into readable sheet structures
  static Map<String, List<List<String>>> parseExcelBackupBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final Map<String, List<List<String>>> result = {};

    for (final tableKey in excel.tables.keys) {
      final sheet = excel.tables[tableKey];
      if (sheet == null) continue;

      final List<List<String>> rows = [];
      for (final row in sheet.rows) {
        final rowStrings = row.map((cell) {
          if (cell == null) return '';
          return cell.value?.toString() ?? '';
        }).toList();
        // Skip completely empty rows
        if (rowStrings.any((s) => s.trim().isNotEmpty)) {
          rows.add(rowStrings);
        }
      }

      if (rows.isNotEmpty) {
        result[tableKey] = rows;
      }
    }

    return result;
  }
}
