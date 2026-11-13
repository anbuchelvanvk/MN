import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'client_concept_theme.dart';
import 'concept_login_screen.dart';

class ConceptAccessScreen extends StatelessWidget {
  const ConceptAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConceptColors.burgundyPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ConceptColors.champagneNude, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Header
              Text(
                'SELECT YOUR ACCESS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ConceptColors.pureWhite,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'UNLOCK YOUR BRILLIANCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ConceptColors.champagneNude.withOpacity(0.85),
                  letterSpacing: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 1. Employee
              _buildAccessCard(
                context,
                title: 'Employee',
                icon: Icons.badge_outlined,
                roleKey: 'employee',
              ),
              const SizedBox(height: 18),

              // 2. Department Lead
              _buildAccessCard(
                context,
                title: 'Department Lead',
                icon: Icons.groups_outlined,
                roleKey: 'dept_head',
              ),
              const SizedBox(height: 18),

              // 3. Hr Admin
              _buildAccessCard(
                context,
                title: 'Hr Admin',
                icon: Icons.shield_outlined,
                roleKey: 'hr',
              ),
              const SizedBox(height: 18),

              // 4. CEO Command
              _buildAccessCard(
                context,
                title: 'CEO Command',
                icon: Icons.workspace_premium_outlined,
                roleKey: 'ceo',
              ),
              
              const Spacer(),

              // Bottom note
              Text(
                'MN JEWEL PARK ECOSYSTEM',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ConceptColors.champagneNude.withOpacity(0.6),
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String roleKey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ConceptColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConceptLoginScreen(defaultRole: roleKey),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ConceptColors.burgundyPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: ConceptColors.burgundyPrimary, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ConceptColors.textDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: ConceptColors.burgundyPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
