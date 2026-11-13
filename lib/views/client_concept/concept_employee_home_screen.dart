import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../pillars/work_pillar_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../dept_head/monthly_scorecard_screen.dart';
import 'client_concept_theme.dart';
import 'concept_home_welcome_screen.dart';

class ConceptEmployeeHomeScreen extends StatefulWidget {
  final String employeeId;
  final String roleKey;

  const ConceptEmployeeHomeScreen({
    super.key,
    this.employeeId = 'MN-1024',
    this.roleKey = 'employee',
  });

  @override
  State<ConceptEmployeeHomeScreen> createState() => _ConceptEmployeeHomeScreenState();
}

class _ConceptEmployeeHomeScreenState extends State<ConceptEmployeeHomeScreen> {
  late final List<Map<String, dynamic>> _primeFocusTasks;

  @override
  void initState() {
    super.initState();
    _primeFocusTasks = [
      {
        'title': 'Dawn Of Excellence',
        'due': 'Due 11:00 AM',
        'status': 'Completed',
        'badgeBg': ConceptColors.badgeGreenBg,
        'badgeText': ConceptColors.badgeGreenText,
      },
      {
        'title': 'GoldGuard Reconciliation',
        'due': 'Due 12.00 PM',
        'status': 'Rejected',
        'badgeBg': ConceptColors.badgeRedBg,
        'badgeText': ConceptColors.badgeRedText,
      },
      {
        'title': 'KaratSure Quality Gate',
        'due': 'Due 1:00 PM',
        'status': 'Pending',
        'badgeBg': ConceptColors.badgeOrangeBg,
        'badgeText': ConceptColors.badgeOrangeText,
      },
      {
        'title': 'Artisan Craftline',
        'due': 'Due 2:00 PM',
        'status': 'Completed',
        'badgeBg': ConceptColors.badgeGreenBg,
        'badgeText': ConceptColors.badgeGreenText,
      },
      {
        'title': 'StockFlow & Order Fulfilment',
        'due': 'Due 3:00 PM',
        'status': 'In Progress',
        'badgeBg': ConceptColors.badgeBlueBg,
        'badgeText': ConceptColors.badgeBlueText,
      },
      {
        'title': 'Golden Seal Closure',
        'due': 'Due 6:00 PM',
        'status': 'Postponed',
        'badgeBg': ConceptColors.badgePurpleBg,
        'badgeText': ConceptColors.badgePurpleText,
      },
    ];
  }

  void _showAddFocusDialog() {
    final titleCtrl = TextEditingController();
    final dueCtrl = TextEditingController(text: 'Due 5:00 PM');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ConceptColors.pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Prime Focus Task',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ConceptColors.burgundyPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Hallmarking Quality Check',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Due Time',
                  hintText: 'e.g. Due 4:30 PM',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ConceptColors.burgundyButton,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _primeFocusTasks.add({
                      'title': titleCtrl.text.trim(),
                      'due': dueCtrl.text.trim(),
                      'status': 'Pending',
                      'badgeBg': ConceptColors.badgeOrangeBg,
                      'badgeText': ConceptColors.badgeOrangeText,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Focus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final activeEmp = eco.employees.firstWhere(
      (e) => e.id == widget.employeeId || e.id == eco.activeEmpId,
      orElse: () => eco.employees.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Luxury Burgundy Profile Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ConceptColors.burgundyDark,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: ConceptColors.burgundyDark.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & On Track Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MN JEWEL PARK',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ConceptColors.pureWhite,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ConceptColors.pureWhite,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'On track',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ConceptColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // User Info and Avatar Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, ${activeEmp.name.split(' ').first == 'MN' ? 'Anbuchelvan' : activeEmp.name}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ConceptColors.pureWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activeEmp.role.isNotEmpty ? activeEmp.role : 'Jewellery Operations Executive'}   ID: ${activeEmp.id.isNotEmpty ? activeEmp.id : 'MN-1024'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: ConceptColors.champagneNude.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: ConceptColors.burgundyPrimary,
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Training / Progress Card (Gold Hallmarking)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ConceptColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE6E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gold Hallmarking & Quality Training',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: ConceptColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '75%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: ConceptColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step 3 of 4: Hallmark Verification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: ConceptColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.75,
                        minHeight: 6,
                        backgroundColor: Color(0xFFF3ECE4),
                        valueColor: AlwaysStoppedAnimation<Color>(ConceptColors.burgundyButton),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Four Quick Action Cards (Work List, Growth Hub, Away Desk, Business Brief)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Work List',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkPillarScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Growth Hub',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MonthlyScorecardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Away Desk',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendancePillarScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Business Brief',
                      onTap: () {
                        CompanyNotificationSheet.show(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Today's Prime Focus Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Prime Focus (${_primeFocusTasks.length})",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: ConceptColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddFocusDialog,
                    child: Text(
                      '+ Add Focus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ConceptColors.burgundyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Six Luxury Burgundy Prime Focus Cards
              ..._primeFocusTasks.map((task) => _buildPrimeFocusCard(task)),

              const SizedBox(height: 24),

              // Return / Exit Navigation
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const ConceptHomeWelcomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: ConceptColors.burgundyPrimary),
                  label: Text(
                    'Return to Concept Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: ConceptColors.burgundyPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ConceptColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE6E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ConceptColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimeFocusCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ConceptColors.burgundyCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ConceptColors.burgundyCard.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: ConceptColors.pureWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task['due'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: ConceptColors.champagneNude.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task['badgeBg'] as Color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: task['badgeText'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  task['status'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: task['badgeText'] as Color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }
}
