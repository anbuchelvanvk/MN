import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../models/employee_model.dart';
import '../../models/hr_attendance_sheet_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/employee_avatar.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _anniversaryController;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late String _relationshipStatus;
  late String _gender;
  bool _savingPhoto = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    final eco = context.read<EcosystemProvider>();
    final emp = eco.currentEmployee;

    _nameController = TextEditingController(text: emp.name);
    _phoneController = TextEditingController(text: emp.phone);
    _dobController = TextEditingController(text: emp.dob);
    _anniversaryController = TextEditingController(text: emp.anniversaryDate);
    _relationshipStatus = Employee.normalizeRelationship(emp.relationshipStatus);
    _gender = Employee.normalizeGender(emp.gender);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _anniversaryController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {DateTime? initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.magentaPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => controller.text = formatted);
    }
  }

  Future<void> _savePersonalDetails(EcosystemProvider eco, Employee emp) async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    await eco.updateEmployeePersonalDetails(
      empId: emp.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      relationshipStatus: _relationshipStatus,
      anniversaryDate: _relationshipStatus == 'Married' ? _anniversaryController.text.trim() : '',
      gender: _gender,
    );

    if (!mounted) return;
    setState(() => _isSavingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Personal profile details updated successfully!'),
        backgroundColor: AppColors.ragGreen,
      ),
    );
  }

  Future<void> _changePhoto(EcosystemProvider eco, Employee emp) async {
    if (_savingPhoto) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.magentaPrimary),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.magentaPrimary),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (emp.avatar.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.ragRed),
                  title: const Text('Remove photo'),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String? avatar;
    try {
      if (choice == 'remove') {
        avatar = '';
      } else {
        avatar = await AvatarPicker.pick(
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (avatar == null) return; // cancelled
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that photo. Please try another one.')),
      );
      return;
    }

    setState(() => _savingPhoto = true);
    final error = await eco.updateEmployeeAvatar(empId: emp.id, avatar: avatar);
    if (!mounted) return;
    setState(() => _savingPhoto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? (avatar.isEmpty ? 'Profile photo removed.' : 'Profile photo updated.')),
        backgroundColor: error == null ? AppColors.ragGreen : AppColors.ragRed,
      ),
    );
  }

  Future<void> _updatePassword(EcosystemProvider eco, Employee emp) async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password do not match.'),
          backgroundColor: AppColors.ragRed,
        ),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters long.'),
          backgroundColor: AppColors.ragRed,
        ),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);
    final error = await eco.changeEmployeePasswordWithReason(
      empId: emp.id,
      oldPassword: oldPass,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isUpdatingPassword = false);

    if (error == null) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully! Keep it confidential.'),
          backgroundColor: AppColors.ragGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.ragRed,
        ),
      );
    }
  }

  void _showForgotPasswordModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.sandGold, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_outlined, color: AppColors.sandGold, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Forgot Your Password?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please contact the HR Department to retrieve or reset your login credentials.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.sandLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
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
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.sandGold),
                      const SizedBox(width: 8),
                      Text(
                        'HR Department (hr@mnj.com)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 15, color: AppColors.sandPrimary),
                      const SizedBox(width: 8),
                      Text(
                        '+91 94433 11000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.sandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 15, color: AppColors.sandPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'hr@mnj.com',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.sandPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: HR has secure administrative authority in the HR Management Portal to verify your staff ID and provide your password directly.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '+919443311000'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HR Phone number copied to clipboard!'),
                  backgroundColor: AppColors.ragGreen,
                ),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'Copy Phone',
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandGold, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'Profile',
        userName: '${emp.name} (${emp.straightCutRole})',
        roleColor: AppColors.sandGold,
        roleIcon: Icons.badge_outlined,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Staff Hero Banner
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                children: [
                  // Profile photo (tap to change)
                  InkWell(
                    onTap: () => _changePhoto(eco, emp),
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 64),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.magentaPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _savingPhoto
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          emp.straightCutDesignation,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            LiquidGlassPill(label: 'ID: ${emp.id}', color: AppColors.sandGold),


                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form 1: Personal Details
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: AppColors.sandGold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Personal Information',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your official contact and family milestones up to date.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    _buildFieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration('Enter your full legal name', Icons.badge_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number
                    _buildFieldLabel('Mobile Phone Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration('+91 98765 43210', Icons.phone_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your mobile number' : null,
                    ),
                    const SizedBox(height: 14),

                    // Date of Birth (DOB)
                    _buildFieldLabel('Date of Birth (DOB)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _dobController),
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration('YYYY-MM-DD', Icons.cake_outlined, suffix: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18, color: AppColors.sandPrimary),
                        onPressed: () => _selectDate(context, _dobController),
                      )),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please select your Date of Birth' : null,
                    ),
                    const SizedBox(height: 14),

                    // Gender (For Grooming Standards Allocation)
                    _buildFieldLabel('Gender (Attire & Grooming Allocation)'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      dropdownColor: AppColors.burgundySurface,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.sandLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                      decoration: _buildInputDecoration('Select Gender', Icons.wc_outlined),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _gender = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Relationship Status
                    _buildFieldLabel('Relationship Status'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _relationshipStatus,
                      dropdownColor: AppColors.burgundySurface,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.sandLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                      decoration: _buildInputDecoration('Select Status', Icons.favorite_border),
                      items: const [
                        DropdownMenuItem(value: 'Single', child: Text('Single')),
                        DropdownMenuItem(value: 'Married', child: Text('Married')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _relationshipStatus = val);
                        }
                      },
                    ),

                    // Anniversary Date (Conditionally visible if Married)
                    if (_relationshipStatus == 'Married') ...[
                      const SizedBox(height: 14),
                      _buildFieldLabel('Marriage Anniversary Date'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _anniversaryController,
                        readOnly: true,
                        onTap: () => _selectDate(context, _anniversaryController, initial: DateTime(2020, 1, 1)),
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                        decoration: _buildInputDecoration('YYYY-MM-DD', Icons.celebration_outlined, suffix: IconButton(
                          icon: const Icon(Icons.calendar_month, size: 18, color: AppColors.sandPrimary),
                          onPressed: () => _selectDate(context, _anniversaryController, initial: DateTime(2020, 1, 1)),
                        )),
                        validator: (val) {
                          if (_relationshipStatus == 'Married' && (val == null || val.trim().isEmpty)) {
                            return 'Please select your marriage anniversary date';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSavingProfile
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSavingProfile ? 'Saving Details...' : 'Save Personal Details',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sandGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSavingProfile ? null : () => _savePersonalDetails(eco, emp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form 2: Password & Confidential Credentials
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_reset, color: AppColors.sandGold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password Security',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your password. Ensure it has at least 6 characters.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Old Password
                    _buildFieldLabel('Current / Old Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration(
                        'Enter your existing password',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.sandPrimary,
                          ),
                          onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 14),

                    // New Password
                    _buildFieldLabel('New Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration(
                        'Enter new password (min 6 characters)',
                        Icons.vpn_key_outlined,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.sandPrimary,
                          ),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Password must be >= 6 characters' : null,
                    ),
                    const SizedBox(height: 14),

                    // Confirm New Password
                    _buildFieldLabel('Confirm New Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: _buildInputDecoration(
                        'Re-type new password to confirm',
                        Icons.check_circle_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppColors.sandPrimary,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Confirm your new password' : null,
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isUpdatingPassword
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.shield_outlined, size: 18),
                        label: Text(
                          _isUpdatingPassword ? 'Updating Password...' : 'Change Password',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundyPrimary,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.sandGold, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isUpdatingPassword ? null : () => _updatePassword(eco, emp),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password Link
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 14, color: AppColors.sandGold),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Forgot Password? Contact HR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sandGold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        onPressed: () => _showForgotPasswordModal(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grooming Points & Compliance Section
            _buildGroomingPointsSection(eco, emp),
            const SizedBox(height: 16),

            // Attendance Last 7 Days Logs Section
            _buildPast7DaysAttendance(eco, emp),
            const SizedBox(height: 16),

            // Logout Button with confirmation
            LogoutConfirmDialog.buildButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroomingPointsSection(EcosystemProvider eco, Employee emp) {
    if (!emp.hasAttendanceAndGrooming) {
      return LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sandGold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.dry_cleaning_outlined, color: AppColors.sandGold, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GROOMING & ATTIRE POINTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                  Text(
                    'Exempt from retail showroom attire & grooming audits',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dailyPoints = eco.getEmployeeGroomingDailyPoints(emp.id);
    final isStar = dailyPoints >= 40;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.sandGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GROOMING COMPLIANCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isStar ? const Color(0xFF10B981).withOpacity(0.15) : AppColors.sandGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isStar ? const Color(0xFF10B981).withOpacity(0.3) : AppColors.sandGold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isStar ? '★ Star' : 'Standard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isStar ? const Color(0xFF10B981) : AppColors.sandGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Grooming Score',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dailyPoints / 50 Points',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${((dailyPoints / 50) * 100).toInt()}% Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPast7DaysAttendance(EcosystemProvider eco, Employee emp) {
    if (!emp.hasAttendanceAndGrooming) {
      return LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATTENDANCE LOGS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                  Text(
                    'Autonomous Leadership Cadence • Biometrics Waived',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final hrSheet = eco.hrAttendanceSheet;
    final hrRow = hrSheet?.findForEmployee(name: emp.name, empNo: emp.empNo);
    final now = DateTime.now();

    final List<Widget> dayItems = [];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayNum = date.day;
      final isTuesday = date.weekday == DateTime.tuesday;
      final dayRec = hrRow?.days[dayNum];

      final dateLabel = i == 0
          ? 'Today (${DateFormat('MMM d').format(date)})'
          : DateFormat('EEE, MMM d').format(date);

      String statusLabel;
      Color statusColor;
      Color statusBg;

      if (isTuesday || (dayRec != null && dayRec.type == HrAttendanceDayType.holiday)) {
        statusLabel = 'Tuesday Week-off';
        statusColor = const Color(0xFF94A3B8);
        statusBg = const Color(0xFF94A3B8).withOpacity(0.12);
      } else if (dayRec != null && dayRec.type != HrAttendanceDayType.pendingUpdate) {
        statusLabel = dayRec.displayLabel;
        switch (dayRec.type) {
          case HrAttendanceDayType.present:
            statusLabel = 'Present (Nil)';
            statusColor = const Color(0xFF10B981);
            statusBg = const Color(0xFF10B981).withOpacity(0.12);
            break;
          case HrAttendanceDayType.late:
            statusLabel = 'Late (${dayRec.rawValue})';
            statusColor = const Color(0xFFF59E0B);
            statusBg = const Color(0xFFF59E0B).withOpacity(0.12);
            break;
          case HrAttendanceDayType.permission:
            statusLabel = 'Permission (${dayRec.rawValue})';
            statusColor = const Color(0xFF3B82F6);
            statusBg = const Color(0xFF3B82F6).withOpacity(0.12);
            break;
          case HrAttendanceDayType.leaveCl:
          case HrAttendanceDayType.leaveLop:
          case HrAttendanceDayType.leaveHalfDay:
            statusLabel = dayRec.displayLabel;
            statusColor = const Color(0xFFEF4444);
            statusBg = const Color(0xFFEF4444).withOpacity(0.12);
            break;
          default:
            statusColor = dayRec.textColor;
            statusBg = dayRec.backgroundColor.withOpacity(0.12);
            break;
        }
      } else {
        statusLabel = 'Yet to update';
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFF59E0B).withOpacity(0.12);
      }

      dayItems.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.sandGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sandLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              )),
            ],
          ),
        ),
      );
    }

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.sandGold, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'RECENT ATTENDANCE',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAST 7 DAYS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Official record from HR Google Sheets Master Ledger',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ...dayItems,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.sandLight,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.burgundySurface,
      prefixIcon: Icon(icon, size: 18, color: AppColors.sandPrimary),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.sandBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.sandBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.sandGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

