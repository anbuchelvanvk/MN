import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/birthday_celebration_dialog.dart';
import '../../core/widgets/daily_pending_actions_dialog.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../chat/chat_hub_screen.dart';
import '../dept_head/team_hub_screen.dart';
import '../employee/employee_profile_screen.dart';
import '../home/modern_home_screen.dart';
import 'role_hubs.dart';
import 'employee_hub_screen.dart';

/// The app's main frame for every signed-in user.
///
/// The V2 home is always the first tab. Managers (CEO / HR / team leads) get
/// their previous dashboard as a separate tab, so nothing they used is lost.
class MainShell extends StatefulWidget {
  /// 'ceo', 'hr', 'dept_head' / 'team_lead' or 'employee'.
  final String role;
  const MainShell({super.key, required this.role});

  /// Maps a resolved login role to the main shell.
  static Widget forRole(String? role) => MainShell(role: (role ?? 'employee').toLowerCase());

  @override
  State<MainShell> createState() => _MainShellState();
}

class _ShellTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final WidgetBuilder builder;
  const _ShellTab(this.label, this.icon, this.activeIcon, this.builder);
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  bool get _isCeo => widget.role == 'ceo';

  List<_ShellTab> get _tabs {
    final workspace = switch (widget.role) {
      'ceo' => _ShellTab('CEO Suite', Icons.workspace_premium_outlined, Icons.workspace_premium_rounded,
          (_) => const CeoHubScreen()),
      'hr' => _ShellTab('HR Desk', Icons.badge_outlined, Icons.badge_rounded,
          (_) => const HrHubScreen()),
      'dept_head' || 'team_lead' => _ShellTab('My Team', Icons.groups_outlined, Icons.groups_rounded,
          (_) => const TeamHubScreen()),
      _ => _ShellTab('My Work', Icons.work_outline_rounded, Icons.work_rounded,
          (_) => const EmployeeHubScreen()),
    };
    return [
      _ShellTab('Home', Icons.home_outlined, Icons.home_rounded,
          (_) => const ModernHomeScreen(isEmbedded: true)),
      _ShellTab('Chat', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,
          (_) => const ChatHubScreen()),
      workspace,
      _ShellTab('Profile', Icons.person_outline_rounded, Icons.person_rounded,
          (_) => const EmployeeProfileScreen()),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final eco = context.read<EcosystemProvider>();
      eco.setLoggedIn(true);
      if (_isCeo && eco.activeEmpId != 'MN-CEO01') {
        eco.setActiveEmpId('MN-CEO01');
      }
      await BirthdayCelebrationDialog.showIfNeeded(context);
      if (!mounted) return;
      await PillarsPopupDialog.show(context);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await DailyPendingActionsDialog.showIfNeeded(context);
    });
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final eco = context.watch<EcosystemProvider>();
    final chatUnread = eco.unreadTotalChatCount;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _select(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: IndexedStack(
          index: _index,
          children: [
            for (int i = 0; i < tabs.length; i++)
              _visited.contains(i)
                  ? KeyedSubtree(key: ValueKey('shell_tab_$i'), child: tabs[i].builder(context))
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: _ShellNavBar(
          tabs: tabs,
          index: _index,
          badges: {1: chatUnread},
          onSelect: _select,
        ),
      ),
    );
  }
}

class _ShellNavBar extends StatelessWidget {
  final List<_ShellTab> tabs;
  final int index;
  final Map<int, int> badges;
  final ValueChanged<int> onSelect;
  const _ShellNavBar({
    required this.tabs,
    required this.index,
    required this.badges,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: Container(
        color: AppColors.canvas,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x332A0F22), blurRadius: 22, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: tabs[i],
                        selected: i == index,
                        badge: badges[i] ?? 0,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _ShellTab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        key: ValueKey('shell_nav_${tab.label}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.goldGradientBright : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? tab.activeIcon : tab.icon,
                    size: 22,
                    color: selected ? AppColors.midnight : const Color(0xFFFFD6E5),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -5,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppColors.ragRed,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.indigoDeep, width: 1.5),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFFFFD6E5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
