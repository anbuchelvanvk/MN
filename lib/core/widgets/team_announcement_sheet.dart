import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// Lets a team lead post an announcement (notice + push) to their team only.
Future<void> showTeamAnnouncementSheet(BuildContext context, EcosystemProvider eco) {
  final titleCtrl = TextEditingController();
  final msgCtrl = TextEditingController();
  final teamCount = eco.myTeamMembers.where((m) => m.id != eco.activeEmpId).length;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final ready = titleCtrl.text.trim().isNotEmpty && msgCtrl.text.trim().isNotEmpty && teamCount > 0;
        InputDecoration deco(String label, String hint) => InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(color: AppColors.magentaSubtle, shape: BoxShape.circle),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.magentaPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Announce to your team', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(
                            teamCount == 0
                                ? 'You have no team members yet.'
                                : 'Goes to your $teamCount team member${teamCount == 1 ? '' : 's'} as a notice and a push notification.',
                            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('announce_title'),
                  controller: titleCtrl,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => set(() {}),
                  decoration: deco('Title', 'e.g. Team meeting at 5 PM'),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('announce_message'),
                  controller: msgCtrl,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => set(() {}),
                  decoration: deco('Message', 'What does your team need to know?'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('announce_send'),
                  onPressed: !ready
                      ? null
                      : () {
                          final sent = eco.announceToMyTeam(titleCtrl.text, msgCtrl.text);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            SnackBar(
                              backgroundColor: sent > 0 ? const Color(0xFF10B981) : const Color(0xFFD97706),
                              content: Text(sent > 0
                                  ? 'Announcement sent to your $sent team member${sent == 1 ? '' : 's'}.'
                                  : 'Nothing sent.'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send announcement'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
