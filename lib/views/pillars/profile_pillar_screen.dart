import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../models/profile_document_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'tier_pillar_screen.dart';

class ProfilePillarScreen extends StatefulWidget {
  const ProfilePillarScreen({super.key});

  @override
  State<ProfilePillarScreen> createState() => _ProfilePillarScreenState();
}

class _ProfilePillarScreenState extends State<ProfilePillarScreen> {
  String? _selectedDropdownDoc;
  String _activeFilter = 'All'; // 'All', 'Submitted', 'Pending'
  int _selectedRingIndex = 1; // 0: Attendance, 1: Documents, 2: Grooming, 3: Sale, 4: Permission, 5: Conduct

  @override
  void initState() {
    super.initState();
    // Default selected option in dropdown
    _selectedDropdownDoc = DocumentTemplates.standardOptions.first['title'];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final employee = provider.currentEmployee;
    final docs = provider.originalDocuments;

    final filteredDocs = docs.where((d) {
      if (_activeFilter == 'Submitted') {
        return d.status == DocumentSubmissionStatus.submitted;
      } else if (_activeFilter == 'Pending') {
        return d.status == DocumentSubmissionStatus.pending;
      }
      return true;
    }).toList();

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
          'STAFF PROFILE',
          style: GoogleFonts.cinzel(
            fontSize: 16,
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
                label: 'PILLAR 3',
                color: AppColors.sandGold,
                icon: Icons.badge_outlined,
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
            // 1. Staff Profile Overview Card
            _buildStaffProfileCard(employee),
            const SizedBox(height: 14),

            // 2. The 6 Professional Profile Rings Matrix
            _buildSixRingsMatrix(context, provider),
            const SizedBox(height: 16),

            // 3. Subsystem Selector Tabs
            _buildSubsystemTabs(),
            const SizedBox(height: 14),

            // 4. Dynamic Subsystem Views based on selected ring
            if (_selectedRingIndex == 0) ...[
              _buildMonthlyAttendanceSection(context, provider),
            ] else if (_selectedRingIndex == 1) ...[
              // Inside here: Document Submission (Original Document Custody)
              _buildVaultMetricsBar(provider),
              const SizedBox(height: 16),
              _buildDropdownAndAddSection(context, provider),
              const SizedBox(height: 16),
              _buildLedgerHeaderWithFilter(docs),
              const SizedBox(height: 10),
              if (filteredDocs.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) => _buildDocumentCard(ctx, provider, filteredDocs[idx]),
                ),
            ] else if (_selectedRingIndex == 2) ...[
              _buildGroomingSection(context, provider),
            ] else if (_selectedRingIndex == 3) ...[
              _buildSalesSection(context, provider),
            ] else if (_selectedRingIndex == 4) ...[
              _buildPermissionSection(context, provider),
            ] else ...[
              _buildEthicsConductSection(context, provider),
            ],
            const SizedBox(height: 20),

            // 5. Direct Gateway to Pillar 4: Tier Rating
            _buildPillar4Gateway(context, provider),
            const SizedBox(height: 12),

            // Logout Button
            LogoutConfirmDialog.buildButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStaffProfileCard(dynamic employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sandGold, width: 2),
              color: AppColors.burgundyPrimary,
            ),
            child: Center(
              child: Text(
                employee.initials,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employee.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                      ),
                      child: Text(
                        employee.id,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  employee.straightCutDesignation,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.sandPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Vault: Locker #B-14',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 6-RING SUBSYSTEM MATRIX ---

  Widget _buildSixRingsMatrix(BuildContext context, EcosystemProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.incomplete_circle_outlined, color: AppColors.sandGold, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'PROFILE RINGS',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                          letterSpacing: 0.6,
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
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                ),
                child: Text(
                  'PILLAR 3 SUITE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any ring to inspect individual subsystem audits, policies, and actions.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // 2 Rows of 3 Rings
          Row(
            children: [
              Expanded(
                child: _buildRingCard(
                  index: 0,
                  title: 'Attendance',
                  displayValue: '${provider.monthlyAttendancePercentage.toStringAsFixed(0)}%',
                  subText: '${provider.workingDaysAttended}/26 Days',
                  progress: (provider.monthlyAttendancePercentage / 100.0).clamp(0.0, 1.0),
                  ringColor: provider.workingDaysAttended == 0
                      ? const Color(0xFF94A3B8)
                      : (provider.monthlyAttendancePercentage >= 90.0 ? AppColors.ragGreen : const Color(0xFFF59E0B)),
                  icon: Icons.fact_check_outlined,
                  statusText: provider.workingDaysAttended == 0
                      ? 'No Punches'
                      : '${provider.monthlyAttendancePercentage.toStringAsFixed(1)}% Ratio',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 1,
                  title: 'Documents',
                  displayValue: '${(provider.documentsSubmissionRatio * 100).toStringAsFixed(0)}%',
                  subText: '${provider.submittedOriginalsCount}/${provider.totalOriginalsCount} Vault',
                  progress: provider.documentsSubmissionRatio,
                  ringColor: provider.totalOriginalsCount == 0
                      ? const Color(0xFF94A3B8)
                      : (provider.pendingOriginalsCount == 0 ? AppColors.ragGreen : const Color(0xFFEF4444)),
                  icon: Icons.lock_clock_outlined,
                  statusText: provider.totalOriginalsCount == 0
                      ? 'Need to be added'
                      : (provider.pendingOriginalsCount == 0 ? 'Custody Safe' : '${provider.pendingOriginalsCount} Pending'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 2,
                  title: 'Grooming',
                  displayValue: '${provider.groomingScore}p',
                  subText: 'Attire & Hair',
                  progress: (provider.groomingScore / 100.0).clamp(0.0, 1.0),
                  ringColor: provider.currentEmployeeGroomingAudits.isEmpty
                      ? const Color(0xFF94A3B8)
                      : (provider.groomingScore >= 80 ? AppColors.sandGold : const Color(0xFFEF4444)),
                  icon: Icons.face_retouching_natural,
                  statusText: provider.currentEmployeeGroomingAudits.isEmpty ? '0 Audits' : 'HR Verified',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRingCard(
                  index: 3,
                  title: 'Showroom Sale',
                  displayValue: '${provider.salesAchievementPercentage.toStringAsFixed(0)}%',
                  subText: '₹${(provider.totalSalesAchieved / 100000).toStringAsFixed(1)}L / ₹25L',
                  progress: (provider.salesAchievementPercentage / 100.0).clamp(0.0, 1.0),
                  ringColor: provider.totalSalesAchieved <= 0
                      ? const Color(0xFF94A3B8)
                      : (provider.salesAchievementPercentage >= 85.0 ? AppColors.sandGold : const Color(0xFFF59E0B)),
                  icon: Icons.monetization_on_outlined,
                  statusText: provider.totalSalesAchieved <= 0
                      ? '₹0.0 Achieved'
                      : '${provider.salesAchievementPercentage.toStringAsFixed(0)}% Target',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 4,
                  title: 'Permissions',
                  displayValue: '${provider.permissionHoursRemaining.toStringAsFixed(1)}h',
                  subText: '${provider.totalPermissionHoursUsed.toStringAsFixed(1)}h Used | 1 CL',
                  progress: (provider.permissionHoursRemaining / provider.monthlyPermissionHoursLimit).clamp(0.0, 1.0),
                  ringColor: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.sandLight,
                  icon: Icons.timer_outlined,
                  statusText: provider.isPermissionExcessHalfDay
                      ? 'Half Day'
                      : '${provider.permissionHoursRemaining.toStringAsFixed(1)}h Left',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 5,
                  title: 'Ethics & Assay',
                  displayValue: provider.conductScore > 0 ? '${provider.conductScore}' : '0.0',
                  subText: provider.conductScore > 0 ? 'Zero Hallmark Lag' : 'No Conduct Audits',
                  progress: provider.conductScore > 0 ? (provider.conductScore / 5.0).clamp(0.0, 1.0) : 0.0,
                  ringColor: provider.conductScore > 0 ? AppColors.ragGreen : const Color(0xFF94A3B8),
                  icon: Icons.verified_user_outlined,
                  statusText: provider.conductScore > 0 ? '${provider.conductScore} / 5.0' : 'Need to be added',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingCard({
    required int index,
    required String title,
    required String displayValue,
    required String subText,
    required double progress,
    required Color ringColor,
    required IconData icon,
    required String statusText,
  }) {
    final isSelected = _selectedRingIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedRingIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sandGold.withOpacity(0.15) : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sandGold.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.2,
                    backgroundColor: AppColors.burgundyCard,
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 16, color: isSelected ? AppColors.sandGold : ringColor),
                        const SizedBox(height: 2),
                        Text(
                          displayValue,
                          style: GoogleFonts.cinzel(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.sandGold : AppColors.sandLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: ringColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: ringColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemTabs() {
    final tabs = [
      {'label': '1. Attendance (26d)', 'icon': Icons.fact_check_outlined},
      {'label': '2. Vault Custody', 'icon': Icons.lock_clock_outlined},
      {'label': '3. Grooming & Attire', 'icon': Icons.face_retouching_natural},
      {'label': '4. Showroom Sales', 'icon': Icons.monetization_on_outlined},
      {'label': '5. Permission & Leave', 'icon': Icons.timer_outlined},
      {'label': '6. Ethics & Hallmark', 'icon': Icons.verified_user_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedRingIndex == idx;
          final tab = tabs[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedRingIndex = idx),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sandGold.withOpacity(0.2) : AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 13,
                      color: isSelected ? AppColors.sandGold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.sandGold : AppColors.sandLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- SUBSYSTEM 0: MONTHLY ATTENDANCE (26 WORKING DAYS) ---

  Widget _buildMonthlyAttendanceSection(BuildContext context, EcosystemProvider provider) {
    final percentage = provider.monthlyAttendancePercentage.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Attendance Metric Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY ATTENDANCE RATIO',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard: 26 Working Days per Calendar Month',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ragGreen.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ragGreen.withOpacity(0.5)),
                    ),
                    child: Text(
                      '$percentage%',
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ragGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (provider.monthlyAttendancePercentage / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.burgundySurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ragGreen),
                ),
              ),
              const SizedBox(height: 14),

              // 4 Stat tiles
              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Standard',
                      value: '${provider.totalWorkingDaysInMonth}',
                      color: AppColors.sandLight,
                      icon: Icons.calendar_month,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Attended',
                      value: '${provider.workingDaysAttended}',
                      color: AppColors.ragGreen,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Casual Leave',
                      value: '1 Day',
                      color: AppColors.sandGold,
                      icon: Icons.beach_access_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Bio Sync',
                      value: 'Live',
                      color: AppColors.sandPrimary,
                      icon: Icons.fingerprint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 26-Day Visual Attendance Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '26-DAY MONTHLY PUNCH MATRIX',
                    style: GoogleFonts.cinzel(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ragGreen)),
                      const SizedBox(width: 4),
                      const Text('Present', style: TextStyle(fontSize: 10, color: AppColors.sandLight)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sandGold)),
                      const SizedBox(width: 4),
                      const Text('CL', style: TextStyle(fontSize: 10, color: AppColors.sandLight)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calendar Grid (26 Days)
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: List.generate(provider.totalWorkingDaysInMonth, (index) {
                  final dayNumber = index + 1;
                  final isCasualLeave = dayNumber == 15;
                  final isUpcoming = dayNumber > provider.workingDaysAttended + 1;
                  final isPresent = !isCasualLeave && !isUpcoming;

                  Color boxColor = isPresent
                      ? AppColors.ragGreen.withOpacity(0.18)
                      : isCasualLeave
                          ? AppColors.sandGold.withOpacity(0.2)
                          : AppColors.burgundyCard;
                  Color borderColor = isPresent
                      ? AppColors.ragGreen.withOpacity(0.5)
                      : isCasualLeave
                          ? AppColors.sandGold
                          : AppColors.sandBorder.withOpacity(0.5);

                  return Container(
                    width: 44,
                    height: 48,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'D$dayNumber',
                          style: GoogleFonts.cinzel(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isPresent
                                ? AppColors.ragGreen
                                : isCasualLeave
                                    ? AppColors.sandGold
                                    : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isPresent
                              ? Icons.check
                              : isCasualLeave
                                  ? Icons.beach_access
                                  : Icons.schedule,
                          size: 13,
                          color: isPresent
                              ? AppColors.ragGreen
                              : isCasualLeave
                                  ? AppColors.sandGold
                                  : AppColors.textMuted,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.sandGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You need at least 90% attendance (24 out of 26 days) to keep a Green status.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.sandLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBSYSTEM 2: GROOMING & ATTIRE ---

  Widget _buildGroomingSection(BuildContext context, EcosystemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grooming Score Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GROOMING AUDIT',
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Attire Standards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
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
                      color: AppColors.sandGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sandGold),
                    ),
                    child: Text(
                      '${provider.groomingScore} / 100',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (provider.groomingScore / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.burgundySurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sandGold),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: AppColors.ragGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Exemplary Showroom Grooming Standard (Grade A)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sandLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Showroom Dress Code Standards Checklist
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHOWROOM ATTIRE CRITERIA CHECKLIST',
                style: GoogleFonts.cinzel(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 10),
              _groomingCheckItem(
                title: 'Professional Haircut & Clean Shave',
                subtitle: 'Tapered hairline, formal side-part, neatly groomed mustache/beard',
                isCompliant: true,
              ),
              const Divider(color: AppColors.sandBorder, height: 14),
              _groomingCheckItem(
                title: 'Showroom Formal Uniform & Blazer',
                subtitle: 'Steam-ironed navy/burgundy blazer, crisp white shirt & tailored trousers',
                isCompliant: true,
              ),
              const Divider(color: AppColors.sandBorder, height: 14),
              _groomingCheckItem(
                title: 'Gold Lapel Pin & Showroom ID',
                subtitle: 'Hallmarked MN insignia pinned on left lapel + magnetic photo ID',
                isCompliant: true,
              ),
              const Divider(color: AppColors.sandBorder, height: 14),
              _groomingCheckItem(
                title: 'Polished Black Leather Oxford Footwear',
                subtitle: 'High-gloss formal leather shoes, matched dark socks, zero scuffs',
                isCompliant: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Real-Time HR Attire Audit Log
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ATTIRE LEDGER',
                      style: GoogleFonts.cinzel(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'By HR Meera',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (provider.groomingAudits.isEmpty)
                Text(
                  'No grooming audits recorded yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.groomingAudits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final audit = provider.groomingAudits[idx];
                    final isPositive = audit.pointsChange >= 0;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPositive
                              ? AppColors.ragGreen.withOpacity(0.3)
                              : const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.ragGreen.withOpacity(0.2)
                                  : const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPositive ? '+${audit.pointsChange} Pts' : '${audit.pointsChange} Pts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? AppColors.ragGreen : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audit.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  audit.reason,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            audit.auditedBy.split(' ').first,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: AppColors.sandGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _groomingCheckItem({
    required String title,
    required String subtitle,
    required bool isCompliant,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCompliant ? Icons.check_circle : Icons.warning_amber_rounded,
          size: 16,
          color: isCompliant ? AppColors.ragGreen : const Color(0xFFEF4444),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBSYSTEM 3: ACTUAL SALES PERFORMANCE ---

  Widget _buildSalesSection(BuildContext context, EcosystemProvider provider) {
    final achievedLakhs = (provider.totalSalesAchieved / 100000).toStringAsFixed(2);
    final targetLakhs = (provider.monthlySalesTarget / 100000).toStringAsFixed(0);
    final remainingLakhs = ((provider.monthlySalesTarget - provider.totalSalesAchieved).clamp(0, double.infinity) / 100000).toStringAsFixed(2);
    final pct = (provider.salesAchievementPercentage * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sales Target & Achieved Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SALES TARGET',
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sales Performance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton(
                    label: 'Log Sale',
                    icon: Icons.add,
                    height: 32,
                    onPressed: () => _openRecordSaleDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: provider.salesAchievementPercentage.clamp(0.0, 1.0),
                  minHeight: 9,
                  backgroundColor: AppColors.burgundySurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sandGold),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Target',
                      value: '₹${targetLakhs}L',
                      color: AppColors.sandLight,
                      icon: Icons.flag_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Achieved',
                      value: '₹${achievedLakhs}L',
                      color: AppColors.sandGold,
                      icon: Icons.monetization_on_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Target %',
                      value: '$pct%',
                      color: AppColors.ragGreen,
                      icon: Icons.trending_up,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Remaining',
                      value: '₹${remainingLakhs}L',
                      color: AppColors.sandPrimary,
                      icon: Icons.hourglass_bottom,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sales Invoices Ledger
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHOWROOM TRANSACTIONS & BILLS LOG',
                style: GoogleFonts.cinzel(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 10),

              if (provider.salesRecords.isEmpty)
                Text(
                  'No sales transactions logged yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.salesRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final sale = provider.salesRecords[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.burgundySurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                            ),
                            child: const Center(
                              child: Icon(Icons.diamond_outlined, size: 18, color: AppColors.sandGold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sale.itemCategory,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                    ),
                                    Text(
                                      '₹${(sale.amountInInr / 100000).toStringAsFixed(2)} Lakhs',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandGold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bill #${sale.billNumber} • ${sale.customerName}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${sale.weightGrams}g Gold/Diamond',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.sandPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openRecordSaleDialog(BuildContext context, EcosystemProvider provider) {
    final billCtrl = TextEditingController(text: 'MN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final custCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = '22K Antique Temple Choker';

    final categories = [
      '22K Antique Temple Choker',
      'VVS Solitaire Bridal Ring',
      '22K Temple Kasu Mala',
      'Polki Kundan Bridal Set',
      'Rose Gold Diamond Bangle',
      'Traditional Navaratna Necklace',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Text(
            'Record Showroom Customer Sale',
            style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogTextField(controller: billCtrl, label: 'Invoice / Bill Number', hint: 'e.g. MN-2026-9041', icon: Icons.receipt),
                const SizedBox(height: 10),
                _dialogTextField(controller: custCtrl, label: 'Customer Name', hint: 'e.g. Smt. Rajeshwari K.', icon: Icons.person_outline),
                const SizedBox(height: 10),
                Text('Jewellery Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.burgundySurface,
                      value: category,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.sandLight)))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => category = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _dialogTextField(controller: weightCtrl, label: 'Gross Weight (Grams)', hint: 'e.g. 45.5', icon: Icons.scale),
                const SizedBox(height: 10),
                _dialogTextField(controller: amtCtrl, label: 'Total Invoice Amount (INR)', hint: 'e.g. 350000', icon: Icons.currency_rupee),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.trim());
                final weight = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                final cust = custCtrl.text.trim().isEmpty ? 'Showroom Customer' : custCtrl.text.trim();
                final bill = billCtrl.text.trim();

                if (bill.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an invoice or bill number')),
                  );
                  return;
                }

                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid invoice amount greater than ₹0')),
                  );
                  return;
                }

                provider.addSalesRecord(
                  empId: provider.currentEmployee.id,
                  billNumber: bill,
                  category: category,
                  amount: amt,
                  weightGrams: weight,
                  customerName: cust,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('Sale of ₹${(amt / 100000).toStringAsFixed(2)} Lakhs recorded!'),
                  ),
                );
              },
              child: Text('Log Sale', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.burgundyBg)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBSYSTEM 4: PERMISSION & LATE ARRIVALS ---

  Widget _buildPermissionSection(BuildContext context, EcosystemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Permission Policy & Account Ledger Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERMISSION & LEAVES',
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly Quota',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton(
                    label: 'Request',
                    icon: Icons.timer,
                    height: 32,
                    onPressed: () => _openRequestPermissionDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Account Status Bar
              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Quota',
                      value: '2.0h',
                      color: AppColors.sandLight,
                      icon: Icons.hourglass_top,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Used',
                      value: '${provider.totalPermissionHoursUsed.toStringAsFixed(1)}h',
                      color: AppColors.sandGold,
                      icon: Icons.history,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Balance',
                      value: '${provider.permissionHoursRemaining.toStringAsFixed(1)}h',
                      color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.ragGreen,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Casual Leave',
                      value: '${provider.casualLeavesUsed}/1',
                      color: AppColors.sandPrimary,
                      icon: Icons.event_busy_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Half Day & Salary Deduction Status Indicators
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isPermissionExcessHalfDay
                        ? const Color(0xFFEF4444)
                        : AppColors.ragGreen.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.isPermissionExcessHalfDay ? Icons.warning : Icons.shield_outlined,
                      size: 18,
                      color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.ragGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.isPermissionExcessHalfDay
                                ? 'Half-Day Leave Triggered'
                                : 'Permission Safe Standing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.sandLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Early arrival automatically credits back to balance.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
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
        ),
        const SizedBox(height: 14),

        // Permission Request History List
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGGED PERMISSION & ARRIVAL REQUESTS',
                style: GoogleFonts.cinzel(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 10),

              if (provider.permissionRecords.isEmpty)
                Text(
                  'No permission requests recorded this month.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.permissionRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final rec = provider.permissionRecords[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.alarm_on, size: 14, color: AppColors.sandGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    rec.reason,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandLight,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.ragGreen.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Credited: +${rec.creditedBackHours.toStringAsFixed(1)}h',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ragGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Requested: ${rec.requestedHours.toStringAsFixed(1)}h  •  Actual Used: ${rec.actualHoursUsed.toStringAsFixed(1)}h',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandLight),
                              ),
                              Text(
                                rec.dateFormatted,
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openRequestPermissionDialog(BuildContext context, EcosystemProvider provider) {
    final reasonCtrl = TextEditingController();
    double requestedHours = 2.0;
    double actualArrivedHours = 1.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final credited = (requestedHours - actualArrivedHours).clamp(0.0, requestedHours);
          final newTotalUsed = provider.totalPermissionHoursUsed + actualArrivedHours;
          final willExceed = newTotalUsed > provider.monthlyPermissionHoursLimit;

          return AlertDialog(
            backgroundColor: AppColors.burgundyCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.sandGold),
            ),
            title: Text(
              'Request Permission / Late Arrival',
              style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogTextField(controller: reasonCtrl, label: 'Reason for Permission', hint: 'e.g. Bank token, medical', icon: Icons.edit_note),
                  const SizedBox(height: 12),

                  Text('Requested Permission Hours:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [0.5, 1.0, 1.5, 2.0].map((h) {
                      final isSel = requestedHours == h;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setDlgState(() => requestedHours = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.sandGold.withOpacity(0.2) : AppColors.burgundySurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? AppColors.sandGold : AppColors.sandBorder),
                              ),
                              child: Text('${h}h', style: TextStyle(fontSize: 11, color: isSel ? AppColors.sandGold : AppColors.sandLight)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('Actual Arrival / Time Spent:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [0.5, 1.0, 1.5, 2.0].map((h) {
                      final isSel = actualArrivedHours == h;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setDlgState(() => actualArrivedHours = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.sandGold.withOpacity(0.2) : AppColors.burgundySurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? AppColors.sandGold : AppColors.sandBorder),
                              ),
                              child: Text('${h}h', style: TextStyle(fontSize: 11, color: isSel ? AppColors.sandGold : AppColors.sandLight)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Real-time calculation preview box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: willExceed ? const Color(0xFFEF4444) : AppColors.ragGreen.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Auto Credit-Back:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                            Text('+${credited.toStringAsFixed(1)}h kept in account', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ragGreen)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Monthly Used:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text('${newTotalUsed.toStringAsFixed(1)}h / 2.0h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: willExceed ? const Color(0xFFEF4444) : AppColors.sandLight)),
                          ],
                        ),
                        if (willExceed) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Warning: Exceeds 2.0h allowance. Will trigger Half-Day Leave.',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sandGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final reason = reasonCtrl.text.trim().isEmpty ? 'General Permission' : reasonCtrl.text.trim();
                  provider.requestPermission(
                    empId: provider.currentEmployee.id,
                    reason: reason,
                    requestedHours: requestedHours,
                    actualHoursUsed: actualArrivedHours,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text('Permission recorded: ${credited.toStringAsFixed(1)}h credited back to account!'),
                    ),
                  );
                },
                child: Text('Submit & Sync', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.burgundyBg)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SUBSYSTEM 5: ETHICS & CONDUCT ---

  Widget _buildEthicsConductSection(BuildContext context, EcosystemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ETHICS & ASSAY',
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Integrity Standards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ragGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ragGreen),
                    ),
                    child: Text(
                      '${provider.conductScore} / 5.0',
                      maxLines: 1,
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ragGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Variance',
                      value: '0.00%',
                      color: AppColors.ragGreen,
                      icon: Icons.verified,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Rating',
                      value: '4.9 ★',
                      color: AppColors.sandGold,
                      icon: Icons.star,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Safe Key',
                      value: 'Passed',
                      color: AppColors.sandLight,
                      icon: Icons.vpn_key_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaultMetricsBar(EcosystemProvider provider) {
    final total = provider.totalOriginalsCount;
    final submitted = provider.submittedOriginalsCount;
    final pending = provider.pendingOriginalsCount;
    final compliancePct = (provider.documentsSubmissionRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'VAULT COMPLIANCE',
                  style: GoogleFonts.cinzel(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pending == 0
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pending == 0
                        ? const Color(0xFF10B981).withOpacity(0.5)
                        : const Color(0xFFEF4444).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  pending == 0 ? '$compliancePct% SECURED' : '$pending ACTION REQUIRED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pending == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricColumn(
                  title: 'Total Tracked',
                  value: '$total',
                  color: AppColors.sandLight,
                  icon: Icons.folder_outlined,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.sandBorder),
              Expanded(
                child: _metricColumn(
                  title: 'In Safe Vault',
                  value: '$submitted',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.sandBorder),
              Expanded(
                child: _metricColumn(
                  title: 'Pending Submit',
                  value: '$pending',
                  color: const Color(0xFFEF4444),
                  icon: Icons.pending_actions_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDropdownAndAddSection(BuildContext context, EcosystemProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppColors.sandGold, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Custody Registry',
                        style: GoogleFonts.cinzel(
                          fontSize: 13.5,
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
              const SizedBox(width: 8),
              // Prominent + Icon button to add custom document
              InkWell(
                onTap: () => _showAddDocumentDialog(context, provider),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sandGold, AppColors.sandPrimary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sandGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle, color: AppColors.burgundyBg, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Add Certificate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundyBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select prefilled standard company originals or add custom ones via the + button:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          // PREFILLED DROPDOWN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AppColors.burgundySurface,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                value: _selectedDropdownDoc,
                items: DocumentTemplates.standardOptions.map((opt) {
                  final title = opt['title']!;
                  final emoji = opt['emoji'] ?? '📜';
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.sandLight,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDropdownDoc = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action bar for the selected dropdown document
          _buildDropdownActionCard(provider),
        ],
      ),
    );
  }

  Widget _buildDropdownActionCard(EcosystemProvider provider) {
    if (_selectedDropdownDoc == null) return const SizedBox.shrink();

    // Check if this document already exists in user's custody ledger
    final existingDoc = provider.originalDocuments.firstWhere(
      (d) => d.title.toLowerCase().contains(_selectedDropdownDoc!.split('(').first.trim().toLowerCase()) ||
             _selectedDropdownDoc!.toLowerCase().contains(d.title.split('(').first.trim().toLowerCase()),
      orElse: () => OriginalDocumentItem(
        id: '',
        title: '',
        category: '',
        status: DocumentSubmissionStatus.pending,
        submissionDate: '',
      ),
    );

    final isAlreadyPresent = existingDoc.id.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundyPrimary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAlreadyPresent ? 'Current Vault Status:' : 'Not in Vault Ledger yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                if (isAlreadyPresent)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: existingDoc.statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        existingDoc.statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: existingDoc.statusColor,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Ready to deposit into safe vault',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sandLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isAlreadyPresent)
            OutlinedButton.icon(
              icon: Icon(
                existingDoc.status == DocumentSubmissionStatus.submitted
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline,
                size: 14,
                color: AppColors.sandGold,
              ),
              label: Text(
                existingDoc.status == DocumentSubmissionStatus.submitted ? 'Mark Pending' : 'Mark Submitted',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sandGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: () {
                final newStatus = existingDoc.status == DocumentSubmissionStatus.submitted
                    ? DocumentSubmissionStatus.pending
                    : DocumentSubmissionStatus.submitted;
                provider.updateOriginalDocumentStatus(existingDoc.id, newStatus);
              },
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload_outlined, size: 14, color: AppColors.burgundyBg),
              label: Text(
                'Submit to Vault',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundyBg,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                final selectedTemplate = DocumentTemplates.standardOptions.firstWhere(
                  (t) => t['title'] == _selectedDropdownDoc,
                  orElse: () => {
                    'title': _selectedDropdownDoc!,
                    'category': 'Academic Record',
                    'emoji': '📜',
                  },
                );

                provider.addOriginalDocument(
                  title: selectedTemplate['title']!,
                  category: selectedTemplate['category'] ?? 'Academic Record',
                  certificateNumber: 'CERT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  status: DocumentSubmissionStatus.submitted,
                  vaultLockerRef: 'Safe Vault Locker #B-14',
                  isMandatory: selectedTemplate['mandatory'] == 'true',
                  iconEmoji: selectedTemplate['emoji'] ?? '📜',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('${selectedTemplate['title']} added and deposited in safe vault!'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLedgerHeaderWithFilter(List<OriginalDocumentItem> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'VAULT LEDGER',
                style: GoogleFonts.cinzel(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', docs.length),
              const SizedBox(width: 6),
              _filterChip(
                'Submitted',
                docs.where((d) => d.status == DocumentSubmissionStatus.submitted).length,
                activeColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              _filterChip(
                'Pending',
                docs.where((d) => d.status == DocumentSubmissionStatus.pending).length,
                activeColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int count, {Color? activeColor}) {
    final isSelected = _activeFilter == label;
    final highlight = activeColor ?? AppColors.sandGold;

    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? highlight.withOpacity(0.2) : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? highlight : AppColors.sandBorder,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? highlight : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, EcosystemProvider provider, OriginalDocumentItem doc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doc.status == DocumentSubmissionStatus.submitted
              ? const Color(0xFF10B981).withOpacity(0.4)
              : const Color(0xFFEF4444).withOpacity(0.4),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Center(
                  child: Text(doc.iconEmoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                        ),
                        if (doc.isMandatory)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.sandGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'MANDATORY',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.category} • Cert #: ${doc.certificateNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.sandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.sandBorder, height: 1),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vault Locker & Date Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          doc.vaultLockerRef,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submitted on: ${doc.submissionDate}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Status Pill / Toggle
              PopupMenuButton<DocumentSubmissionStatus>(
                color: AppColors.burgundySurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.sandBorder),
                ),
                initialValue: doc.status,
                onSelected: (newStatus) {
                  provider.updateOriginalDocumentStatus(doc.id, newStatus);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: DocumentSubmissionStatus.submitted,
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text('Submitted (Vault)', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: DocumentSubmissionStatus.pending,
                    child: Row(
                      children: const [
                        Icon(Icons.pending, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 8),
                        Text('Pending Submission', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: DocumentSubmissionStatus.verifying,
                    child: Row(
                      children: const [
                        Icon(Icons.hourglass_top, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 8),
                        Text('Under Verification', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: doc.statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: doc.statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: doc.statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        doc.statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: doc.statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 14, color: doc.statusColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),
              // Delete icon for custom items
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                onPressed: () => _confirmDeleteDocument(context, provider, doc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_off_outlined, color: AppColors.sandGold, size: 36),
            const SizedBox(height: 8),
            Text(
              'No documents found in this filter',
              style: GoogleFonts.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select from dropdown above or click the + button to add.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillar4Gateway(BuildContext context, EcosystemProvider provider) {
    final tier = provider.holisticTierLevel;
    final color = provider.holisticTierColor;
    final tierName = provider.holisticTierName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 18,
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
                child: LiquidGlassPill(
                  label: 'GREEN FACTOR',
                  color: AppColors.sandGold,
                  icon: Icons.light_mode,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                child: Text(
                  tier == PillarTierLevel.green ? 'CRITERIA MET' : 'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'How Documents Affect Your Status',
            style: GoogleFonts.cinzel(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.sandLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitting your original documents helps you maintain a Green status ($tierName). Keeping all required documents safely submitted ensures your status stays green.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.sandPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.radar_outlined, size: 16, color: AppColors.burgundyBg),
            label: Text(
              'Check Your Overall Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.burgundyBg,
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

  // --- DIALOGS ---

  void _showAddDocumentDialog(BuildContext context, EcosystemProvider provider) {
    final titleCtrl = TextEditingController();
    final certCtrl = TextEditingController();
    final lockerCtrl = TextEditingController();
    String selectedCategory = 'Academic Marksheet';
    DocumentSubmissionStatus selectedStatus = DocumentSubmissionStatus.submitted;
    bool isMandatory = true;
    String selectedEmoji = '📜';

    const categories = [
      'Academic Marksheet',
      'Degree Certificate',
      'Academic Record',
      'Identity Proof',
      'Employment Record',
      'Trade License',
      'Health Record',
      'Other Official Original',
    ];

    const emojis = ['📜', '🎓', '📑', '🪪', '💳', '📄', '💍', '🛂', '🏥', '⭐'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.sandGold, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: AppColors.sandGold, size: 22),
              const SizedBox(width: 10),
              Text(
                'Add Original Document',
                style: GoogleFonts.cinzel(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit original certificate record into company vault:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),

                // Title input
                _dialogTextField(
                  controller: titleCtrl,
                  label: 'Document Title / Description',
                  hint: 'e.g. 10th Marksheet, M.Tech Degree, TC...',
                  icon: Icons.title,
                ),
                const SizedBox(height: 10),

                // Certificate Number
                _dialogTextField(
                  controller: certCtrl,
                  label: 'Register / Certificate Number',
                  hint: 'e.g. SSLC-2016-887410',
                  icon: Icons.tag,
                ),
                const SizedBox(height: 10),

                // Category dropdown
                Text(
                  'Category',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.burgundySurface,
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.sandLight)))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Safe Vault Locker Reference
                _dialogTextField(
                  controller: lockerCtrl,
                  label: 'Safe Vault Locker Box',
                  hint: 'Company Safe Vault Locker #B-14',
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 10),

                // Custody Status Selection
                Text(
                  'Submission Status',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _statusChoiceChip(
                        label: 'Submitted',
                        selected: selectedStatus == DocumentSubmissionStatus.submitted,
                        color: const Color(0xFF10B981),
                        onTap: () => setDlgState(() => selectedStatus = DocumentSubmissionStatus.submitted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _statusChoiceChip(
                        label: 'Pending',
                        selected: selectedStatus == DocumentSubmissionStatus.pending,
                        color: const Color(0xFFEF4444),
                        onTap: () => setDlgState(() => selectedStatus = DocumentSubmissionStatus.pending),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Mandatory Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.sandGold,
                  title: Text(
                    'Mandatory for Company Verification',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.sandLight),
                  ),
                  value: isMandatory,
                  onChanged: (v) => setDlgState(() => isMandatory = v),
                ),

                // Emoji Picker
                Text(
                  'Icon Emoji',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: emojis.map((e) {
                    final isPicked = selectedEmoji == e;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedEmoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPicked ? AppColors.sandGold.withOpacity(0.3) : AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isPicked ? AppColors.sandGold : AppColors.sandBorder),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                provider.addOriginalDocument(
                  title: title,
                  category: selectedCategory,
                  certificateNumber: certCtrl.text.trim().isEmpty ? 'N/A' : certCtrl.text.trim(),
                  status: selectedStatus,
                  vaultLockerRef: lockerCtrl.text.trim().isEmpty ? 'Safe Vault Locker #B-14' : lockerCtrl.text.trim(),
                  isMandatory: isMandatory,
                  iconEmoji: selectedEmoji,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('"$title" added to vault ledger!'),
                  ),
                );
              },
              child: Text(
                'Save to Vault',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundyBg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandLight),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 16, color: AppColors.sandGold),
            filled: true,
            fillColor: AppColors.burgundySurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.sandBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.sandBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChoiceChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.25) : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppColors.sandBorder, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : AppColors.sandLight,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDocument(BuildContext context, EcosystemProvider provider, OriginalDocumentItem doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.sandBorder),
        ),
        title: Text(
          'Remove Document Record?',
          style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
        content: Text(
          'Are you sure you want to remove "${doc.title}" from the custody tracking registry?',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              provider.deleteOriginalDocument(doc.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document record removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
