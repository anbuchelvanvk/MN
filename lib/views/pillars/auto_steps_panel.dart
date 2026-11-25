import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/auto_steps_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';

/// "Count steps automatically" switch for the Health pillar. Works with
/// Health Connect on Android and Apple Health on iPhone; typing steps in by
/// hand keeps working either way.
class AutoStepsPanel extends StatelessWidget {
  const AutoStepsPanel({super.key});

  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final source = eco.autoStepsSourceName;

    if (!eco.autoStepsSupported) {
      return _shell(
        icon: Icons.phone_iphone_rounded,
        color: AppColors.sandPrimary,
        title: 'Automatic steps',
        subtitle: 'Works in the phone app (Android and iPhone). Here, type your steps in.',
      );
    }

    final status = eco.autoStepsStatus;
    final enabled = eco.autoStepsEnabled;
    final problem = enabled &&
        (status == AutoStepsStatus.needsPermission || status == AutoStepsStatus.needsHealthConnect);

    String subtitle;
    if (!enabled) {
      subtitle = 'Fill in your steps from $source. You can still type them in.';
    } else if (status == AutoStepsStatus.needsHealthConnect) {
      subtitle = 'Health Connect is missing or needs an update.';
    } else if (status == AutoStepsStatus.needsPermission) {
      subtitle = 'Step access is turned off in $source.';
    } else if (eco.autoStepsSyncing) {
      subtitle = 'Reading steps from $source…';
    } else {
      subtitle = 'From $source • ${_ago(eco.autoStepsLastSync)}';
    }

    return _shell(
      icon: Icons.directions_walk_rounded,
      color: problem ? _amber : (enabled ? _green : AppColors.sandGold),
      title: 'Auto-count steps',
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled && !problem)
            eco.autoStepsSyncing
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    key: const Key('auto_steps_refresh'),
                    tooltip: 'Refresh steps',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.sandGold),
                    onPressed: () => eco.syncAutoSteps(force: true),
                  ),
          Switch.adaptive(
            key: const Key('auto_steps_switch'),
            value: enabled,
            activeTrackColor: _green,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            onChanged: (v) => v ? _turnOn(context, eco) : _turnOff(context, eco),
          ),
        ],
      ),
      footer: problem
          ? _FixRow(
              text: status == AutoStepsStatus.needsHealthConnect
                  ? 'Install or update Health Connect, then come back.'
                  : 'Allow MN Family to read Steps.',
              button: status == AutoStepsStatus.needsHealthConnect ? 'Get Health Connect' : 'Allow',
              onTap: () => status == AutoStepsStatus.needsHealthConnect
                  ? eco.openHealthConnectInstall()
                  : _turnOn(context, eco, skipIntro: true),
            )
          : (enabled && eco.autoStepsNoData && !eco.autoStepsSyncing)
              ? _Hint(_noDataHint())
              : null,
    );
  }

  static String _noDataHint() => AutoStepsService.isIOS
      ? 'No steps found yet. If this stays at 0, open the Settings app › Health › Data Access & Devices › MN Family, and turn on Steps.'
      : 'No steps found yet. Carry your phone while you walk. If you use Google Fit or Samsung Health, connect it to Health Connect.';

  static String _ago(DateTime? t) {
    if (t == null) return 'not synced yet';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'updated just now';
    if (d.inMinutes < 60) return 'updated ${d.inMinutes} min ago';
    if (d.inHours < 24) return 'updated ${d.inHours} h ago';
    return 'updated ${d.inDays} d ago';
  }

  Future<void> _turnOff(BuildContext context, EcosystemProvider eco) async {
    await eco.disableAutoSteps();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Automatic steps off. Steps already saved stay as they are.')),
    );
  }

  Future<void> _turnOn(BuildContext context, EcosystemProvider eco, {bool skipIntro = false}) async {
    final source = eco.autoStepsSourceName;
    if (!skipIntro) {
      final go = await showAdaptiveDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog.adaptive(
          title: const Text('Count steps automatically?'),
          content: Text(
            'MN Family will ask $source for permission to read your steps. '
            'It only reads steps — nothing else, and it never changes your health data.\n\n'
            '${AutoStepsService.isIOS ? 'On the next screen, turn on "Steps" and tap Allow.' : 'On the next screen, allow "Steps".'}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
          ],
        ),
      );
      if (go != true) return;
    }

    final result = await eco.enableAutoSteps();
    if (!context.mounted) return;
    switch (result) {
      case AutoStepsStatus.on:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Automatic steps on. Steps update from $source each time you open the app.')),
        );
      case AutoStepsStatus.needsHealthConnect:
        await _info(
          context,
          title: 'Health Connect needed',
          body: 'Android keeps step counts in the free Health Connect app. Install or update it, then turn this on again.',
          action: 'Get Health Connect',
          onAction: eco.openHealthConnectInstall,
        );
      case AutoStepsStatus.needsPermission:
        await _info(
          context,
          title: 'Steps not allowed',
          body: 'MN Family could not read your steps. Turn this on again and allow "Steps" '
              'on the $source screen. You can always type steps in instead.',
        );
      case AutoStepsStatus.off:
      case AutoStepsStatus.unsupported:
        break;
    }
  }

  static Future<void> _info(
    BuildContext context, {
    required String title,
    required String body,
    String? action,
    Future<void> Function()? onAction,
  }) {
    return showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          if (action != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onAction?.call();
              },
              child: Text(action),
            ),
        ],
      ),
    );
  }

  Widget _shell({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.midnight),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A6A74), height: 1.3),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 8), footer],
        ],
      ),
    );
  }
}

class _FixRow extends StatelessWidget {
  final String text;
  final String button;
  final VoidCallback onTap;
  const _FixRow({required this.text, required this.button, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF92400E), height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: onTap,
            child: Text(button, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.sandPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
