import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';

/// Shared building blocks for the role tabs (CEO Suite, HR Desk, My Team).

void openHubScreen(BuildContext context, Widget screen) {
  final eco = context.read<EcosystemProvider>();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(value: eco, child: screen),
    ),
  );
}

class HubTool {
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  const HubTool(this.icon, this.label, this.hint, this.color, this.onTap, {this.badge = 0});
}

class HubStat {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const HubStat(this.icon, this.value, this.label, this.color, {this.onTap});
}

/// Row of three summary cards.
class HubStatsRow extends StatelessWidget {
  final List<HubStat> stats;
  const HubStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _StatCard(stat: stats[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final HubStat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: stat.onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, size: 18, color: stat.color),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  style: GoogleFonts.outfit(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.1),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured attention banner (absentees, approvals waiting...).
class HubAlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const HubAlertBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onAction,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of tools.
class HubToolGrid extends StatelessWidget {
  final List<HubTool> tools;
  const HubToolGrid({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final t in tools) SizedBox(width: w, child: _ToolTile(tool: t))],
        );
      },
    );
  }
}

class _ToolTile extends StatelessWidget {
  final HubTool tool;
  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: tool.onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tool.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tool.icon, size: 20, color: tool.color),
                  ),
                  if (tool.badge > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.ragRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          tool.badge > 99 ? '99+' : '${tool.badge}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    Text(
                      tool.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact person row: photo, name, role, status chip.
class HubPersonRow extends StatelessWidget {
  final Employee employee;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;
  const HubPersonRow({
    super.key,
    required this.employee,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              EmployeeAvatar(avatar: employee.avatar, initials: employee.initials, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text(employee.straightCutDesignation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple full page that hosts an existing section widget (e.g. announcements).
class HubSectionPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const HubSectionPage({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: title, subtitle: subtitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [child],
      ),
    );
  }
}
