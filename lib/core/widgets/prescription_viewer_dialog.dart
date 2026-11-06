import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_pillar_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// Modal to view uploaded doctor's prescription in high detail (with zoom)
/// and allow HR / CEO to approve or reject emergency medical leave.
class PrescriptionViewerDialog extends StatelessWidget {
  final MedicalLeaveRecord leave;
  final bool isCeo;
  final bool isHr;

  const PrescriptionViewerDialog({
    super.key,
    required this.leave,
    this.isCeo = false,
    this.isHr = false,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicalLeaveRecord leave,
    bool isCeo = false,
    bool isHr = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrescriptionViewerDialog(
        leave: leave,
        isCeo: isCeo,
        isHr: isHr,
      ),
    );
  }

  Uint8List _decodeImage(String base64Str) {
    try {
      final clean = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      return base64Decode(clean);
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImage(leave.prescriptionBase64);

    return Dialog(
      backgroundColor: AppColors.burgundyCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.sandPrimary, width: 1.5),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 480,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: AppColors.sandGold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor Prescription Review',
                        style: GoogleFonts.cinzel(
                          color: AppColors.sandGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${leave.empName} • ${leave.empRole} (${leave.days} Days)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.sandLight, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),

            // Leave Reason details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reason for Leave:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ragRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ragRed, width: 0.8),
                        ),
                        child: Text(
                          '${leave.days} Days • ${leave.dateFormatted}',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.ragRed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leave.reason,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${leave.status}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: leave.status == 'Approved'
                          ? AppColors.ragGreen
                          : leave.status == 'Rejected'
                              ? AppColors.ragRed
                              : AppColors.sandGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Interactive Prescription Image Viewer (Pinch to zoom)
            Text(
              'Doctor Prescription (Pinch to Zoom):',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandPrimary.withOpacity(0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes.isNotEmpty
                    ? InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text(
                                'Unable to display prescription image.',
                                style: TextStyle(color: AppColors.ragRed, fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          'No prescription attached.',
                          style: TextStyle(color: AppColors.ragRed, fontSize: 11),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons for HR or CEO
            if (leave.status != 'Approved' && leave.status != 'Rejected') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ragRed,
                        side: const BorderSide(color: AppColors.ragRed),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final eco = EcosystemProvider();
                        eco.rejectMedicalLeave(
                          leave.id,
                          rejectedBy: isCeo ? 'CEO' : 'HR',
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Medical Leave request rejected.')),
                        );
                      },
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCeo ? AppColors.ragGreen : AppColors.sandGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final eco = EcosystemProvider();
                        if (isCeo) {
                          eco.ceoApproveMedicalLeave(leave.id);
                        } else {
                          eco.hrGrantMedicalLeave(leave.id);
                        }
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCeo
                                  ? 'Emergency Medical Leave approved by CEO!'
                                  : 'Medical Leave endorsed by HR & forwarded to CEO.',
                            ),
                          ),
                        );
                      },
                      icon: Icon(isCeo ? Icons.check_circle : Icons.verified_user, size: 14),
                      label: Text(
                        isCeo ? 'Accept Medical Leave' : 'Grant / Forward to CEO',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close Viewer', style: TextStyle(color: AppColors.sandLight)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
