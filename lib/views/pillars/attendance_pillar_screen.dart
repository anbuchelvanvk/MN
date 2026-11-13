import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
import '../../models/attendance_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'tier_pillar_screen.dart';

class AttendancePillarScreen extends StatefulWidget {
  const AttendancePillarScreen({super.key});

  @override
  State<AttendancePillarScreen> createState() => _AttendancePillarScreenState();
}

class _AttendancePillarScreenState extends State<AttendancePillarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerPulseController;
  late Animation<double> _scannerPulseAnimation;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scannerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scannerPulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _scannerPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final todayLogin = provider.todayLoginPunch;
    final todayLogout = provider.todayLogoutPunch;
    final isOnDuty = provider.isCurrentlyOnDuty;
    final statusLabel = provider.attendanceStatusLabel;
    final statusColor = provider.attendanceStatusColor;


    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sandPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ATTENDANCE',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: LiquidGlassPill(
                label: 'PILLAR 4 • DAILY',
                color: statusColor,
                icon: Icons.fingerprint,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Today's Attendance Status Card (Login/Logout/Duration)
            _buildTodayAttendanceCard(context, provider, todayLogin, todayLogout, isOnDuty, statusLabel, statusColor),
            const SizedBox(height: 16),

            // Emergency Permission (15m/30m/1h/2h/>2h) & Medical Leave Section
            _buildEmergencyPermissionsAndLeavesSection(context, provider),
            const SizedBox(height: 16),

            // 2. In-App Attendance Punch Module
            _buildThumbScannerModule(context, provider, isOnDuty),
            const SizedBox(height: 16),

            // 3. Tabular Column: Your Recent Activities (Past 7 Days) for Self Review
            _buildPast7DaysActivityTable(context, provider),
            const SizedBox(height: 16),

            // 4. Sovereign Green Light Impact Gateway
            _buildGreenLightGateway(context, provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTodayAttendanceCard(
    BuildContext context,
    EcosystemProvider provider,
    AttendancePunchRecord? login,
    AttendancePunchRecord? logout,
    bool isOnDuty,
    String statusLabel,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S ATTENDANCE STATUS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily Cadence • Punch In, Breaks & Punch Out Recorded with Date & Time',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Primary Metrics: Login & Logout
          Row(
            children: [
              // LOGIN TIME
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.login, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Punch In',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        login != null ? login.timeString : '--:-- --',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: login != null ? AppColors.sandLight : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        login != null ? 'In-App Punch (On-Time)' : 'Scheduled: 09:30 AM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: login != null ? const Color(0xFF10B981) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // LOGOUT TIME
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.logout, size: 14, color: Color(0xFFEF4444)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Punch Out',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        logout != null ? logout.timeString : (isOnDuty ? 'On Duty' : '--:-- --'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isOnDuty ? const Color(0xFFF59E0B) : (logout != null ? AppColors.sandLight : AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnDuty ? 'Shift ongoing (Active)' : (logout != null ? 'Shift completed' : 'Standard: 06:00 PM'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: isOnDuty ? const Color(0xFFF59E0B) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shift Working Duration Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.burgundyPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 15, color: AppColors.sandGold),
                    const SizedBox(width: 6),
                    Text(
                      'Net Hours:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    login != null 
                      ? '${provider.todayNetWorkDurationHours.toStringAsFixed(1)}h (${provider.todayLunchDurationMinutes}m lunch)' 
                      : 'Not clocked in',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandGold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // LUNCH BREAK DEDICATED TRACKER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.isCurrentlyOnLunch 
                    ? const Color(0xFFF59E0B) 
                    : AppColors.sandBorder.withOpacity(0.6),
                width: provider.isCurrentlyOnLunch ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (provider.isCurrentlyOnLunch ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    provider.isCurrentlyOnLunch ? Icons.restaurant_menu : Icons.free_breakfast_outlined,
                    size: 18,
                    color: provider.isCurrentlyOnLunch ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Lunch Window',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.isCurrentlyOnLunch)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: const Text(
                                'ON BREAK NOW',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.todayLunchOutPunch != null
                            ? '${provider.todayLunchOutPunch!.timeString} → ${provider.todayLunchInPunch?.timeString ?? "Active (${provider.todayLunchDurationMinutes}m)"}'
                            : 'No Lunch Punch Recorded Yet (Window: 1:00 PM - 2:00 PM)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: provider.todayLunchOutPunch != null ? AppColors.sandGold : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbScannerModule(BuildContext context, EcosystemProvider provider, bool isOnDuty) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    FaIcon(FontAwesomeIcons.bolt, size: 16, color: AppColors.sandGold),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Punch Station',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Text(
                  'In-App Active',
                  style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mark your attendance directly in-app: Push the button or tap quick action buttons for In, Lunch and Out:',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Central Tactile Push Button to Mark Punch Log
          ScaleTransition(
            scale: _scannerPulseAnimation,
            child: GestureDetector(
              onTap: () => _handlePunchLogInteraction(provider, isOnDuty),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isScanning
                        ? [
                            const Color(0xFF34D399),
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                          ]
                        : (isOnDuty
                            ? [
                                const Color(0xFF34D399),
                                const Color(0xFF10B981),
                                const Color(0xFF047857),
                              ]
                            : [
                                const Color(0xFFFB7185),
                                AppColors.sandGold,
                                const Color(0xFF9D174D),
                              ]),
                  ),
                  border: Border.all(
                    color: _isScanning
                        ? const Color(0xFFA7F3D0)
                        : (isOnDuty ? const Color(0xFF6EE7B7) : const Color(0xFFFECDD3)),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isScanning || isOnDuty)
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : AppColors.sandGold.withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      _isScanning
                          ? FontAwesomeIcons.arrowsRotate
                          : FontAwesomeIcons.handPointer,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isScanning ? 'RECORDING...' : 'PUSH TO LOG',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Direct Quick Action Punch Buttons (In, Lunch Out, Lunch In, Out)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login, size: 14, color: AppColors.burgundyBg),
                      label: Text(
                        '1. Login (In)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundyBg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.login);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Text('Attendance log verified: Login check-in recorded!'),
                            ),
                          );
                        } else if (provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant_outlined, size: 14, color: Colors.white),
                      label: Text(
                        '2. Lunch Out',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.breakOut);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFF59E0B),
                              content: Text('Lunch break started! Timer active in audit ledger.'),
                            ),
                          );
                        } else if (provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.free_breakfast, size: 14, color: Colors.white),
                      label: Text(
                        '3. Lunch In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.breakIn);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF3B82F6),
                              content: Text('Lunch break ended! Resumed active duty.'),
                            ),
                          );
                        } else if (provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, size: 14, color: Colors.white),
                      label: Text(
                        '4. Logout (Out)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.logout);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFEF4444),
                              content: Text('Attendance log verified: Logout check-out recorded!'),
                            ),
                          );
                        } else if (provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPast7DaysActivityTable(BuildContext context, EcosystemProvider provider) {
    final records = provider.getPast7DaysAttendanceForEmployee(provider.activeEmpId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Card Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.table_chart_outlined, color: AppColors.sandGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Recent Activities (Past 7 Days)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Login, logout, lunch in/out & hours for self-review',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: const Text(
                    '1-Week Data',
                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.sandBorder, height: 1),

          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 48,
              horizontalMargin: 16,
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.all(AppColors.burgundySurface),
              columns: const [
                DataColumn(
                  label: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                ),
                DataColumn(
                  label: Text('Login Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ),
                DataColumn(
                  label: Text('Lunch Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                ),
                DataColumn(
                  label: Text('Lunch In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ),
                DataColumn(
                  label: Text('Logout Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                ),
                DataColumn(
                  label: Text('Hours & Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight)),
                ),
              ],
              rows: records.map((r) {
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (r.dateLabel.startsWith('Today')) {
                      return AppColors.sandGold.withOpacity(0.08);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.dateLabel.startsWith('Today'))
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          Text(
                            r.dateLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: r.dateLabel.startsWith('Today') ? FontWeight.bold : FontWeight.w500,
                              color: r.dateLabel.startsWith('Today') ? AppColors.sandGold : AppColors.sandLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        r.loginTime,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.lunchOutTime,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.lunchInTime,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.logoutTime,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: r.logoutTime.contains('Active') ? const Color(0xFF10B981) : AppColors.sandLight,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: r.statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          '${r.netHours} • ${r.status}',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: r.statusColor),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  Widget _buildGreenLightGateway(BuildContext context, EcosystemProvider provider) {
    final color = provider.holisticTierColor;
    final isRed = color == AppColors.ragRed;
    final isGreen = color == AppColors.ragGreen;
    final pillBg = isRed
        ? const Color(0xFFFFF1F2)
        : (isGreen ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB));
    final pillBorder = isRed
        ? const Color(0xFFFECDD3)
        : (isGreen ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A));
    final pillTextColor = isRed
        ? const Color(0xFFE11D48)
        : (isGreen ? const Color(0xFF059669) : const Color(0xFFD97706));

    final isAttendanceOnTime = provider.hasLoggedAttendanceToday && provider.isAttendanceOnTime;
    final statusPillBg = isAttendanceOnTime ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);
    final statusPillBorder = isAttendanceOnTime ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3);
    final statusPillTextColor = isAttendanceOnTime ? const Color(0xFF059669) : const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pillBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.light_mode, size: 12, color: pillTextColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Green Factor',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: pillTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusPillBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusPillBorder, width: 1),
                  ),
                  child: Text(
                    isAttendanceOnTime ? 'On-Time Verified' : 'Attendance Pending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusPillTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Attendance Impact',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.sandLight,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Punching in on time with your thumb on the biometric machine keeps your status Green.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.radar_outlined, size: 16, color: Colors.white),
            label: Text(
              'Check Overall Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TierPillarScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- ACTIONS & DIALOGS ---

  void _handlePunchLogInteraction(EcosystemProvider provider, bool isOnDuty) {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isScanning = false);

      // Prompt for punch action
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.sandGold, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  FaIcon(FontAwesomeIcons.clipboardCheck, size: 20, color: AppColors.ragGreen),
                  SizedBox(width: 10),
                  Text(
                    'Attendance Punch Log Verified',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'In-App attendance profile matched: ${provider.currentEmployee.name} (${provider.currentEmployee.id}). Select punch action:',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: const Icon(Icons.login, color: AppColors.burgundyBg, size: 16),
                label: const Text('Record Work Login (Check-In)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: AppColors.burgundyBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.login);
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Attendance punch recorded: Work Login (In)'),
                      ),
                    );
                  } else if (provider.notificationMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFEF4444),
                        content: Text(provider.notificationMessage!),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                label: const Text('Record Work Logout (Check-Out)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.logout);
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFFEF4444),
                        content: Text('Attendance punch recorded: Work Logout (Out)'),
                      ),
                    );
                  } else if (provider.notificationMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFEF4444),
                        content: Text(provider.notificationMessage!),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sandBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.breakOut);
                        Navigator.pop(ctx);
                        if (!ok && provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                      child: const Text('Break Out', style: TextStyle(color: AppColors.sandGold, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sandBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final ok = provider.recordThumbImpressionPunch(punchType: AttendancePunchType.breakIn);
                        Navigator.pop(ctx);
                        if (!ok && provider.notificationMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text(provider.notificationMessage!),
                            ),
                          );
                        }
                      },
                      child: const Text('Break In', style: TextStyle(color: AppColors.sandGold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Emergency Permissions (15m, 30m, 1h, 2h, >2h) & Medical Leave Section
  Widget _buildEmergencyPermissionsAndLeavesSection(BuildContext context, EcosystemProvider provider) {
    final permissions = provider.currentEmployeePermissionRecords;
    final medicalLeaves = provider.currentEmployeeMedicalLeaves;
    final usedHours = provider.totalPermissionHoursUsed;
    final remainingHours = provider.permissionHoursRemaining;
    final isOverQuota = usedHours > 2.0;

    return LiquidGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.sandGold.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: AppColors.sandGold, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY PASS & MEDICAL LEAVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Direct CEO & HR approval pipeline',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two Action Buttons: Emergency Permission & Emergency Medical Leave
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  onPressed: () => EmergencyPermissionModal.show(context),
                  icon: const FaIcon(FontAwesomeIcons.clock, size: 13, color: Colors.white),
                  label: const Text(
                    'Permission',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  onPressed: () => EmergencyMedicalLeaveModal.show(context),
                  icon: const FaIcon(FontAwesomeIcons.kitMedical, size: 13, color: Colors.white),
                  label: const Text(
                    'Medical Leave',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2.0 Hours Permission Quota Tally Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverQuota ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOverQuota ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2-Hour Monthly Quota Tally', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        '${usedHours.toStringAsFixed(1)}h Used • ${remainingHours.toStringAsFixed(1)}h Remaining',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverQuota
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOverQuota ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isOverQuota ? '⚠️ Over 2h (Orange Mark)' : 'Quota Healthy',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isOverQuota ? const Color(0xFFD97706) : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent Requests List
          if (permissions.isNotEmpty || medicalLeaves.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Your Active Requests:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            const SizedBox(height: 6),
            ...permissions.map((p) {
              final isOrange = p.isOrangeFlagged || p.requestedHours > 2.0;
              final durStr = p.actualHoursUsed < 1.0 ? '${(p.actualHoursUsed * 60).round()}m' : '${p.actualHoursUsed}h';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isOrange ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOrange ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOrange ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 15,
                      color: isOrange ? const Color(0xFFD97706) : AppColors.sandGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Emergency Permission ($durStr)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOrange ? const Color(0xFFD97706) : AppColors.textDark,
                                ),
                              ),
                              if (isOrange) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFF59E0B), width: 0.6),
                                  ),
                                  child: const Text(
                                    '>2h Orange Mark',
                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            p.reason,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.status == 'Approved'
                            ? const Color(0xFFECFDF5)
                            : p.status == 'Rejected'
                                ? const Color(0xFFFFF1F2)
                                : const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: p.status == 'Approved'
                              ? const Color(0xFFA7F3D0)
                              : p.status == 'Rejected'
                                  ? const Color(0xFFFECDD3)
                                  : const Color(0xFFFBCFE8),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: p.status == 'Approved'
                              ? const Color(0xFF059669)
                              : p.status == 'Rejected'
                                  ? const Color(0xFFE11D48)
                                  : AppColors.sandGold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            ...medicalLeaves.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 15, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Leave (${m.days} Days)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            m.reason,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => PrescriptionViewerDialog.show(context, leave: m),
                      icon: const Icon(Icons.image, size: 12, color: AppColors.sandGold),
                      label: const Text('Prescription', style: TextStyle(fontSize: 9.5, color: AppColors.sandGold)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
