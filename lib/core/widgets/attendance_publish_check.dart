import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// Checkpoint before "Attendance updated" goes to every staff phone.
/// Returns true when it is fine to send (no problems, or HR chose
/// "Publish anyway").
Future<bool> confirmAttendancePublish(BuildContext context, EcosystemProvider eco, String dateText) async {
  final report = eco.checkAttendanceBeforePublish(dateText);
  if (report.problemCount == 0) return true;
  final lines = report.lines;
  final shown = lines.take(8).toList();
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      icon: const Icon(Icons.fact_check_rounded, color: Color(0xFFD97706), size: 36),
      title: Text(
        report.problemCount == 1 ? '1 problem in the sheet' : '${report.problemCount} problems in the sheet',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fix these in the Google Sheet before telling everyone, or publish anyway.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            for (final l in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l, style: GoogleFonts.outfit(fontSize: 12.5, height: 1.3))),
                  ],
                ),
              ),
            if (lines.length > shown.length)
              Text('…and ${lines.length - shown.length} more.',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Fix first')),
        FilledButton(
          key: const Key('publish_anyway'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
          onPressed: report.sheetMissing ? null : () => Navigator.pop(ctx, true),
          child: const Text('Publish anyway'),
        ),
      ],
    ),
  );
  return go == true;
}
