import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../providers/ecosystem_provider.dart';
import '../../core/services/session_store.dart';
import '../shell/main_shell.dart';

class LoginScreen extends StatefulWidget {
  final bool isSwitchAccount;
  const LoginScreen({super.key, this.isSwitchAccount = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class SessionManager {
  static Future<void> logout(BuildContext context) async {
    try {
      final eco = context.read<EcosystemProvider>();
      eco.resetSession();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      await SessionStore.clear();
    } catch (_) {}
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  /// Category 3, Item 12: Auto-login session restore on process reclaim / cold start
  Future<void> _checkSavedSession() async {
    if (widget.isSwitchAccount) return;
    try {
      // Firebase may restore the user a moment after launch; wait for it.
      // The saved session is never wiped here - only the Logout action clears it.
      final session = await SessionStore.restore();
      if (session == null) return;
      final savedEmail = session.email;
      final savedRole = session.role;
      final savedEmpId = session.empId;

      if (savedEmpId.isNotEmpty && mounted) {
        final eco = context.read<EcosystemProvider>();
        eco.setLoggedIn(true);
        eco.setActiveEmpId(savedEmpId, fallbackRole: savedRole);
        await eco.loadEmployeeFourPillars(savedEmpId);

        if (!mounted) return;
        Widget targetScreen;
        final resolvedRole = savedRole;

        if (savedEmpId == 'MN-CEO01' ||
            resolvedRole == 'ceo' ||
            savedEmail.toLowerCase().contains('ceoofmn')) {
          targetScreen = const MainShell(role: 'ceo');
        } else {
          switch (resolvedRole) {
            case 'hr':
              targetScreen = const MainShell(role: 'hr');
              break;
            case 'dept_head':
            case 'team_lead':
              targetScreen = const MainShell(role: 'dept_head');
              break;
            case 'ceo':
              targetScreen = const MainShell(role: 'ceo');
              break;
            case 'employee':
            default:
              targetScreen = const MainShell(role: 'employee');
              break;
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      }
    } catch (e) {
      debugPrint('Auto-login session note: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text; // Trimmed consistently by the provider for login and password changes

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email or staff ID');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your account password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final eco = context.read<EcosystemProvider>();

    try {
      final detectedRole = await eco.loginWithFirebase(
        email: email,
        password: password,
      );
      eco.setLoggedIn(true);

      // Category 3, Item 12: Persist session to local storage
      try {
        await SessionStore.save(
          empId: eco.activeEmpId,
          role: detectedRole,
          email: FirebaseAuth.instance.currentUser?.email ?? email,
        );
      } catch (err) {
        debugPrint('Session saving note: $err');
      }

      if (!mounted) return;

      Widget targetScreen;
      if (eco.activeEmpId == 'MN-CEO01' || detectedRole == 'ceo' || email.toLowerCase().contains('ceoofmn')) {
        targetScreen = const MainShell(role: 'ceo');
      } else {
        switch (detectedRole) {
          case 'hr':
            targetScreen = const MainShell(role: 'hr');
            break;
          case 'dept_head':
          case 'team_lead':
            targetScreen = const MainShell(role: 'dept_head');
            break;
          case 'ceo':
            targetScreen = const MainShell(role: 'ceo');
            break;
          case 'employee':
          default:
            targetScreen = const MainShell(role: 'employee');
            break;
        }
      }

      final messenger = ScaffoldMessenger.of(context);
      final employeeName = eco.currentEmployee.name;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
      if (widget.isSwitchAccount) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Switched account to $employeeName'),
            backgroundColor: AppColors.ragGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Email / Password incorrect';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('timeout') || errStr.contains('unavailable')) {
          msg = 'Network connection error. Please check your internet connectivity.';
        } else if (errStr.contains('user-not-found')) {
          msg = 'No staff account registered for this email / ID.';
        } else if (errStr.contains('wrong-password')) {
          msg = 'Incorrect password. Please verify your credentials.';
        } else if (errStr.contains('invalid-credential')) {
          // Firebase returns this for both unknown emails and wrong passwords
          msg = 'Incorrect email or password.';
        } else if (errStr.contains('not active')) {
          msg = 'This account is not active. Please contact HR.';
        } else if (errStr.contains('too-many-requests')) {
          msg = 'Access temporarily locked due to repeated failed attempts. Please try again later.';
        }
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0F22), Color(0xFF881337), Color(0xFF9F1239)],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glowing gradient spheres for executive depth & warmth
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.heroAccent.withOpacity(0.22),
                      AppColors.heroAccent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryBright.withOpacity(0.30),
                      AppColors.primaryBright.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.15),
                      const Color(0xFFF59E0B).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violet.withOpacity(0.25),
                      AppColors.violet.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  if (widget.isSwitchAccount) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.heroAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: Text(
                          'Back to Current Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Brand Monogram & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.heroAccent,
                              width: 2.4,
                            ),
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.heroAccent.withOpacity(0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.diamond_outlined,
                                color: AppColors.magentaPrimary,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MN JEWEL PARK',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'MN Family • Staff app',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.heroAccent,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Liquid Glass Card
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 28,
                    backgroundColor: Colors.white,
                    borderColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSwitchAccount ? 'Switch Account' : 'Sign in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isSwitchAccount
                              ? 'Sign in to another account. Tap back above to return to your current session without logging out.'
                              : 'Enter your official credentials to sign in.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (widget.isSwitchAccount) ...[
                          Builder(
                            builder: (context) {
                              EcosystemProvider? eco;
                              try {
                                eco = Provider.of<EcosystemProvider>(context);
                              } catch (_) {}
                              final currentName = eco?.currentEmployee.name ?? 'Current User';
                              final currentRole = eco?.currentEmployee.straightCutRole ?? 'Staff';
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.burgundySurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.sandBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ACTIVE ACCOUNT',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF10B981),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            '$currentName ($currentRole)',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.sandLight,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 18),
                        ],


                        // Email Address Input
                        Text(
                          'Email',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.burgundySurface,
                            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.sandPrimary),
                            hintText: 'Official email',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandGold, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sandLight,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showForgotPasswordDialog(context),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.sandGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) {
                            if (!_isLoading) _handleLogin();
                          },
                          style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.burgundySurface,
                            prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.sandPrimary),
                            hintText: 'Password',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: AppColors.sandPrimary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.sandGold, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 22),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.ragRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.ragRed.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: AppColors.ragRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.ragRed, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Login Action Button
                        _isLoading
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          color: AppColors.sandGold,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Validating credentials...',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.sandGold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LiquidGlassButton(
                                label: widget.isSwitchAccount ? 'Switch Account' : 'Sign In',
                                icon: widget.isSwitchAccount ? Icons.switch_account : Icons.login,
                                height: 48,
                                onPressed: _handleLogin,
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
    ],
  ),
),
);
}

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: AppColors.sandGold),
            const SizedBox(width: 8),
            Text(
              'Password Assistance',
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We can email a secure reset link to your official email address. '
              'If you no longer have access to that inbox, contact the HR department.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 13, color: AppColors.sandPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HR Department: hr@mnj.com',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.sandGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.burgundyPrimary),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final email = _emailController.text.trim().toLowerCase();
              Navigator.pop(ctx);
              if (!email.contains('@')) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Enter your official email above first, then tap Forgot Password again.')),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              } catch (_) {
                // Do not reveal whether the account exists
              }
              messenger.showSnackBar(
                SnackBar(content: Text('If $email is a staff account, a reset link has been sent to it.')),
              );
            },
            child: const Text('Email me a reset link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
