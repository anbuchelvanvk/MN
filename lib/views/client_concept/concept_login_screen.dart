import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import 'client_concept_theme.dart';
import 'concept_employee_home_screen.dart';
import 'concept_signup_screen.dart';

class ConceptLoginScreen extends StatefulWidget {
  final String defaultRole;
  const ConceptLoginScreen({super.key, this.defaultRole = 'employee'});

  @override
  State<ConceptLoginScreen> createState() => _ConceptLoginScreenState();
}

class _ConceptLoginScreenState extends State<ConceptLoginScreen> {
  final _idCtrl = TextEditingController(text: 'MN-1024');
  final _passwordCtrl = TextEditingController(text: 'password123');
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.defaultRole == 'ceo') {
      _idCtrl.text = 'MN-CEO01';
    } else if (widget.defaultRole == 'hr') {
      _idCtrl.text = 'MN-HR1001';
    } else if (widget.defaultRole == 'dept_head') {
      _idCtrl.text = 'MN-TL2001';
    } else {
      _idCtrl.text = 'MN-1024';
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final eco = context.read<EcosystemProvider>();
    final empId = _idCtrl.text.trim().isEmpty ? 'MN-1024' : _idCtrl.text.trim();
    eco.setActiveEmpId(empId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConceptEmployeeHomeScreen(
          employeeId: empId,
          roleKey: widget.defaultRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConceptColors.champagneNude,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ConceptColors.burgundyPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Header Title
              Text(
                'LOGIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ConceptColors.burgundyPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 38),

              // 1. Employee ID / Username Field
              _buildPillField(
                controller: _idCtrl,
                hintText: 'Employee ID / Username',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 18),

              // 2. Password Field
              _buildPillField(
                controller: _passwordCtrl,
                hintText: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: ConceptColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              // Remember me & Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: ConceptColors.burgundyPrimary,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: ConceptColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: ConceptColors.burgundyPrimary,
                          content: Text(
                            'Password reset link dispatched to registered company email.',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: ConceptColors.textDark.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // LOGIN Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConceptColors.burgundyButton,
                    foregroundColor: ConceptColors.pureWhite,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _handleLogin,
                  child: Text(
                    'LOGIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: ConceptColors.pureWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Or divider
              Text(
                'Or',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ConceptColors.textDark.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Biometric Fingerprint Button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ConceptColors.burgundyPrimary,
                      content: Text(
                        'Biometric authenticated for Anbuchelvan (ID: MN-1024)!',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                    ),
                  );
                  _handleLogin();
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: ConceptColors.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: ConceptColors.burgundyPrimary,
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Don't have an account? Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: ConceptColors.textDark.withOpacity(0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConceptSignUpScreen()),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: ConceptColors.burgundyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ConceptColors.pureWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: ConceptColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: ConceptColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }
}
