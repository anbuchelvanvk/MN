import '../../core/widgets/personal_todo_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../providers/ecosystem_provider.dart';
import '../pillars/social_cause_pillar_screen.dart';
import 'employee_profile_screen.dart';
import '../../core/widgets/mn_app_bar.dart';

/// Reusable Scaffold for all Employee Subpages (Clean White/Magenta styling with top-left back button)
class EmployeeSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const EmployeeSubpageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MnAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// 1. THINGS TO DO SUBPAGE
class EmployeeThingsToDoScreen extends StatefulWidget {
  const EmployeeThingsToDoScreen({super.key});

  @override
  State<EmployeeThingsToDoScreen> createState() => _EmployeeThingsToDoScreenState();
}

class _EmployeeThingsToDoScreenState extends State<EmployeeThingsToDoScreen> {
  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    return EmployeeSubpageScaffold(
      title: 'My Tasks',
      subtitle: 'Daily routines, to-dos & follow-ups',
      body: RefreshIndicator(
        color: AppColors.magentaPrimary,
        backgroundColor: Colors.white,
        onRefresh: () => eco.refreshAllData(),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: PersonalTodoSectionWidget(),
        ),
      ),
    );
  }
}


// 2. SOCIAL CAUSE SUBPAGE
class EmployeeSocialCauseScreen extends StatelessWidget {
  const EmployeeSocialCauseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeeSubpageScaffold(
      title: 'Social Cause',
      subtitle: 'Pillar 5 CSR & Community Impact',
      body: SocialCausePillarScreen(isStandalone: false),
    );
  }
}

// 3. DIGITAL ID VAULT SUBPAGE
class EmployeeDigitalIdScreen extends StatelessWidget {
  const EmployeeDigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;

    return EmployeeSubpageScaffold(
      title: 'Digital ID Vault',
      subtitle: 'Official Workforce Credentials & Custody',
      actions: [
        IconButton(
          icon: const Icon(Icons.badge_outlined, color: Colors.white),
          tooltip: 'Open Full Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Employee Digital ID Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.magentaPrimary, Color(0xFFBE185D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x22E11D48), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Row(
                        children: [
                          const Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Flexible(child: Text(
                            'MN JEWEL PARK',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),),                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          'OFFICIAL ID',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Text(
                          emp.initials,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.role,
                              style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white.withOpacity(0.85)),
                            ),
                            Text(
                              'ID: ${emp.id} • ${emp.dept}',
                              style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('Vault Security Status', style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white.withOpacity(0.85)))),
                        Text('VERIFIED ACTIVE', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile & KYC Details Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(
                        'Personal & Contact Details',
                        style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      )),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                          );
                        },
                        child: Text(
                          'Edit Profile',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', emp.phone.isNotEmpty ? emp.phone : 'Not provided'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.email_outlined, 'Official Email', emp.email),
                  const SizedBox(height: 8),
                  _infoRow(Icons.corporate_fare_outlined, 'Department', emp.dept),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today_outlined, 'Date of Birth', emp.dob.isNotEmpty ? emp.dob : 'Not provided'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.favorite_outline, 'Relationship Status', emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Portal Access Credentials
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portal Access & Credentials',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  Row(
                    children: [
                      const Icon(Icons.key_outlined, size: 16, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Login & password',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.magentaPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        child: const Text('Change', style: TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.magentaPrimary),
        const SizedBox(width: 8),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 130), child: Text('$label: ', overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted))),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
