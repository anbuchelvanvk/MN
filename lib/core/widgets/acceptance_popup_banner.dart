import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/acceptance_notification_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// Floating In-App Pop-up Banner that appears at the top of the screen
/// to notify HR, CEO, and TL whenever a permission or leave request is accepted.
class AcceptancePopupBanner extends StatefulWidget {
  final AcceptancePopupNotification popup;

  const AcceptancePopupBanner({
    super.key,
    required this.popup,
  });

  @override
  State<AcceptancePopupBanner> createState() => _AcceptancePopupBannerState();
}

class _AcceptancePopupBannerState extends State<AcceptancePopupBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );

    _animCtrl.forward();

    // Auto-dismiss after 7 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 7), () {
      _dismiss();
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    await _animCtrl.reverse();
    if (mounted) {
      context.read<EcosystemProvider>().acknowledgeAcceptancePopup(widget.popup.id);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popup = widget.popup;
    final isPerm = popup.requestType == AcceptanceRequestType.permission;
    final categoryTitle = isPerm ? 'PERMISSION ACCEPTED' : 'LEAVE REQUEST ACCEPTED';

    return SafeArea(
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Material(
              color: Colors.transparent,
              elevation: 16,
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  _autoDismissTimer?.cancel();
                  AcceptanceNotificationDetailModal.show(context, popup);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF064E3B), // Deep Emerald
                        Color(0xFF0F172A), // Luxury Dark Slate
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981), // Emerald green border
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Notification Header Strip
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF34D399),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 13,
                                      color: Color(0xFF34D399),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      categoryTitle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF34D399),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• Just now',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: _dismiss,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar circle
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    popup.employeeName.isNotEmpty
                                        ? popup.employeeName[0].toUpperCase()
                                        : 'E',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${popup.employeeName} (${popup.employeeRole})',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${popup.durationOrDays} • ${popup.reason}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFCBD5E1),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            popup.approvedBy,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF34D399),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Audience distribution indicator strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          color: Colors.black.withOpacity(0.35),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.campaign_rounded,
                                size: 13,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Notified to: HR • CEO • Team Lead',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFBBF24),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail Modal that opens when tapping the acceptance notification popup
class AcceptanceNotificationDetailModal extends StatelessWidget {
  final AcceptancePopupNotification popup;

  const AcceptanceNotificationDetailModal({
    super.key,
    required this.popup,
  });

  static Future<void> show(BuildContext context, AcceptancePopupNotification popup) {
    return showDialog(
      context: context,
      builder: (ctx) => AcceptanceNotificationDetailModal(popup: popup),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPerm = popup.requestType == AcceptanceRequestType.permission;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Top Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4ADE80)),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF166534),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPerm ? 'Permission Accepted' : 'Leave Request Accepted',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Official Executive Endorsement',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 16),

            // Employee Details
            _detailRow('Staff Member', popup.employeeName, isBold: true),
            const SizedBox(height: 8),
            _detailRow('Designation', popup.employeeRole),
            const SizedBox(height: 8),
            _detailRow('Department', popup.employeeDept),
            const SizedBox(height: 8),
            _detailRow('Duration / Days', popup.durationOrDays, textColor: const Color(0xFF047857), isBold: true),
            const SizedBox(height: 8),
            _detailRow('Reason Stated', popup.reason),
            const SizedBox(height: 8),
            _detailRow('Approved By', popup.approvedBy, textColor: AppColors.sandGold, isBold: true),

            const SizedBox(height: 16),
            // Verified Distribution Checklist
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OFFICIAL POP-UP NOTIFICATION RECIPIENTS',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sandGold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _checklistRow('HR Department', true),
                  _checklistRow('Executive CEO', true),
                  _checklistRow('Team Lead (Praveenkumar M)', true),
                  _checklistRow('Applicant Staff (${popup.employeeName})', true),
                ],
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context.read<EcosystemProvider>().acknowledgeAcceptancePopup(popup.id);
                Navigator.pop(context);
              },
              child: const Text('Acknowledge & Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _detailRow(String label, String value, {Color? textColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _checklistRow(String label, bool isNotified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NOTIFIED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
