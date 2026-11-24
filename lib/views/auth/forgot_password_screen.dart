import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/password_reset_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mn_app_bar.dart';

/// Staff password reset, verified by HR:
///  1. enter email -> get a 5-character code
///  2. tell the code to HR; HR enters it in "Password requests"
///  3. once approved, set a new password here.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, waiting, newPassword, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Step _step = _Step.email;
  PendingPasswordReset? _pending;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String _waitingNote = '';
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail ?? '';
    _resume();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resume() async {
    final p = await PasswordResetService.loadPending();
    if (p == null || !mounted) return;
    final age = DateTime.now().millisecondsSinceEpoch - (p.expiresAt - 30 * 60 * 1000);
    if (age > 2 * 60 * 60 * 1000) {
      await PasswordResetService.clearPending();
      return;
    }
    setState(() {
      _pending = p;
      _emailCtrl.text = p.email;
      _step = _Step.waiting;
    });
    _startPolling();
  }

  Future<void> _requestCode() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your official email address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await PasswordResetService.request(email);
      if (!mounted) return;
      setState(() {
        _pending = p;
        _step = _Step.waiting;
        _waitingNote = '';
      });
      _startPolling();
    } on PasswordResetException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _tick?.cancel();
    _checkStatus();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkStatus() async {
    final p = _pending;
    if (p == null || _step != _Step.waiting) return;
    try {
      final s = await PasswordResetService.status(p);
      if (!mounted || _step != _Step.waiting) return;
      switch (s) {
        case 'approved':
          _poll?.cancel();
          setState(() => _step = _Step.newPassword);
          break;
        case 'completed':
          _poll?.cancel();
          await PasswordResetService.clearPending();
          setState(() => _step = _Step.done);
          break;
        case 'expired':
        case 'locked':
        case 'cancelled':
          _poll?.cancel();
          await PasswordResetService.clearPending();
          setState(() {
            _step = _Step.email;
            _pending = null;
            _error = s == 'locked'
                ? 'Too many wrong codes were entered. Please request a new code.'
                : 'That code is no longer valid. Please request a new one.';
          });
          break;
        default:
          if (_waitingNote.isNotEmpty) setState(() => _waitingNote = '');
      }
    } on PasswordResetException catch (e) {
      if (mounted) setState(() => _waitingNote = e.message);
    }
  }

  Future<void> _savePassword() async {
    final p = _pending;
    if (p == null) return;
    final pass = _passCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'Use at least 6 characters');
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = 'The two passwords do not match');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PasswordResetService.complete(p, pass);
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } on PasswordResetException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOver() async {
    _poll?.cancel();
    _tick?.cancel();
    await PasswordResetService.clearPending();
    if (!mounted) return;
    setState(() {
      _pending = null;
      _step = _Step.email;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MnAppBar(title: 'Reset password', subtitle: 'Verified by HR'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _StepsBar(current: _step.index.clamp(0, 2)),
            const SizedBox(height: 18),
            _card(
              switch (_step) {
                _Step.email => _emailStep(),
                _Step.waiting => _waitingStep(),
                _Step.newPassword => _passwordStep(),
                _Step.done => _doneStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: child,
      );

  Widget _title(String t, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 18),
        ],
      );

  Widget _errorText() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.ragRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.ragRed, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

  Widget _emailStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('Forgot your password?', 'Enter your official email. You will get a 5-character code to give to HR.'),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !_busy,
            onSubmitted: (_) => _requestCode(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'name@mnj.com',
            ),
          ),
          _errorText(),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _requestCode,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.key_rounded),
            label: const Text('Get my code'),
          ),
        ],
      );

  Widget _waitingStep() {
    final p = _pending!;
    final left = Duration(milliseconds: (p.expiresAt - DateTime.now().millisecondsSinceEpoch).clamp(0, 1 << 31));
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Give this code to HR', 'Tell HR this code in person or on a call. Do not share it in a group chat.'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final ch in p.code.split(''))
                    Container(
                      width: 46,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ch,
                        style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.indigoDeep),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: p.code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text('Copy code • valid for $mm:$ss', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _waitingNote.isNotEmpty ? _waitingNote : 'Waiting for HR to enter the code for ${p.email}…',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You can close the app; this request stays open on this phone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: _startOver, child: const Text('Start over')),
      ],
    );
  }

  Widget _passwordStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('HR approved ✓', 'Set a new password for ${_pending?.email ?? 'your account'}.'),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            enabled: !_busy,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: 'New password (min 6 characters)',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            enabled: !_busy,
            onSubmitted: (_) => _savePassword(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.verified_user_outlined),
              hintText: 'Type it again',
            ),
          ),
          _errorText(),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _savePassword,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: const Text('Save new password'),
          ),
        ],
      );

  Widget _doneStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.ragGreen),
          const SizedBox(height: 12),
          Text(
            'Password changed',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in with your new password. Other phones signed in to this account were signed out.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_emailCtrl.text.trim()),
            child: const Text('Back to sign in'),
          ),
        ],
      );
}

class _StepsBar extends StatelessWidget {
  final int current;
  const _StepsBar({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Your email', 'HR verifies', 'New password'];
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.primary : AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                    color: i <= current ? AppColors.textDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
