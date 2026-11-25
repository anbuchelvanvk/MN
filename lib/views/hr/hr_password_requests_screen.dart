import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/password_reset_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/mn_app_bar.dart';

/// HR / CEO: staff who asked to reset their password. Pick the person and type
/// the 5-character code they read out; that lets them set a new password.
class HrPasswordRequestsScreen extends StatelessWidget {
  const HrPasswordRequestsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream() {
    try {
      return FirebaseFirestore.instance
          .collection('password_reset_queue')
          .where('status', whereIn: ['pending', 'approved'])
          .snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MnAppBar(title: 'Password requests', subtitle: 'Verify staff with their code'),
      body: stream == null
          ? const _Message(icon: Icons.cloud_off_rounded, text: 'Not connected. Check the internet and reopen this page.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const _Message(icon: Icons.error_outline_rounded, text: 'Could not load requests. Pull down or reopen this page.');
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final now = DateTime.now().millisecondsSinceEpoch;
                final docs = snap.data!.docs
                    .where((d) => ((d.data()['expiresAt'] ?? 0) as num) > now)
                    .toList()
                  ..sort((a, b) => ((b.data()['createdAt'] ?? 0) as num).compareTo((a.data()['createdAt'] ?? 0) as num));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    const _HowItWorks(),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      const _Message(icon: Icons.lock_open_rounded, text: 'No open requests right now.')
                    else
                      for (final d in docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequestCard(id: d.id, data: d.data()),
                        ),
                  ],
                );
              },
            ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5D0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'When someone taps "Forgot password" they get a 5-character code. '
              'Confirm it is really them, then enter their code here. '
              'Their phone will then let them set a new password.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const _RequestCard({required this.id, required this.data});

  String _ago(num? ms) {
    if (ms == null) return '';
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms.toInt()));
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    return '${d.inHours} h ago';
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final approved = data['status'] == 'approved';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          EmployeeAvatar(avatar: '', initials: initials.isEmpty ? '?' : initials, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? email : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Text(
                  '$email • ${_ago(data['createdAt'] as num?)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                ),
                if (approved)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Verified • waiting for them to set a new password',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ragGreen),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!approved)
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              onPressed: () => _enterCode(context, name.isEmpty ? email : name),
              child: const Text('Enter code'),
            )
          else
            const Icon(Icons.verified_rounded, color: AppColors.ragGreen),
        ],
      ),
    );
  }

  Future<void> _enterCode(BuildContext context, String who) async {
    final ctrl = TextEditingController();
    String? error;
    bool busy = false;
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setD) {
          Future<void> submit() async {
            if (ctrl.text.trim().length != 5) {
              setD(() => error = 'The code has 5 characters');
              return;
            }
            setD(() {
              busy = true;
              error = null;
            });
            try {
              final name = await PasswordResetService.hrVerify(id, ctrl.text);
              if (dCtx.mounted) Navigator.pop(dCtx);
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.ragGreen,
                  content: Text('Verified. ${name.isEmpty ? who : name} can now set a new password.'),
                ),
              );
            } on PasswordResetException catch (e) {
              setD(() {
                busy = false;
                error = e.message;
              });
            }
          }

          return AlertDialog(
            title: Text('Verify $who'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask them to read out the code shown on their phone.',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  enabled: !busy,
                  maxLength: 5,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    TextInputFormatter.withFunction(
                      (o, n) => n.copyWith(text: n.text.toUpperCase()),
                    ),
                  ],
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 8),
                  decoration: InputDecoration(counterText: '', hintText: 'ABC12', errorText: error),
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(dCtx), child: const Text('Cancel')),
              FilledButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBB8C4)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
