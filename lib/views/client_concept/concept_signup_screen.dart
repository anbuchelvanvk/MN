import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'client_concept_theme.dart';
import 'concept_login_screen.dart';

class ConceptSignUpScreen extends StatefulWidget {
  const ConceptSignUpScreen({super.key});

  @override
  State<ConceptSignUpScreen> createState() => _ConceptSignUpScreenState();
}

class _ConceptSignUpScreenState extends State<ConceptSignUpScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedDept = 'Online Department';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: ConceptColors.burgundyPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ConceptColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Header Title
              Text(
                'SIGN UP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ConceptColors.burgundyPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Username
              _buildPillField(
                controller: _usernameCtrl,
                hintText: 'Username',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 18),

              // 2. Email Address
              _buildPillField(
                controller: _emailCtrl,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // 3. Password
              _buildPillField(
                controller: _passwordCtrl,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 18),

              // 4. Date of Birth
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: _buildPillField(
                    controller: _dobCtrl,
                    hintText: 'Date of Birth',
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Gender
              _buildPillField(
                controller: _genderCtrl,
                hintText: 'Gender',
              ),
              const SizedBox(height: 18),

              // 6. Department
              _buildPillField(
                controller: _deptCtrl,
                hintText: 'Department',
              ),
              const SizedBox(height: 32),

              // Sign Up Action Button
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: ConceptColors.burgundyPrimary,
                        content: Text(
                          'Account created successfully! Please sign in.',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        ),
                      ),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ConceptLoginScreen()),
                    );
                  },
                  child: Text(
                    'SIGN UP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: ConceptColors.pureWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Already have an account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: ConceptColors.textDark.withOpacity(0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ConceptLoginScreen()),
                      );
                    },
                    child: Text(
                      'Log In',
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
        ),
      ),
    );
  }

  Widget _buildPillDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ConceptColors.burgundyPrimary),
          dropdownColor: ConceptColors.pureWhite,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: ConceptColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          alignment: AlignmentDirectional.center,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              alignment: AlignmentDirectional.center,
              child: Text(
                item.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: ConceptColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
