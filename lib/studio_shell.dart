import 'package:flutter/material.dart';

import 'app_feedback.dart';
import 'app_theme.dart';
import 'editor_chrome.dart';
import 'home_page.dart';
import 'studio_tabs.dart';

class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int _index = 0;
  final _projectsKey = GlobalKey<ProjectsTabState>();

  static const _tabs = [
    _StudioTab(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Hjem',
    ),
    _StudioTab(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'Prosjekter',
    ),
    _StudioTab(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Layouts',
    ),
    _StudioTab(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  void _onTabSelected(int index) {
    if (index == _index) return;
    AppFeedback.selection();
    setState(() => _index = index);
    if (index == 1) {
      _projectsKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: switch (_index) {
        0 => HomePage(onDraftsChanged: () => _projectsKey.currentState?.reload()),
        1 => ProjectsTab(key: _projectsKey),
        2 => const LayoutsTab(),
        _ => const ProfileTab(),
      },
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.cream,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              EditorChrome.spaceSm,
              EditorChrome.spaceLg,
              EditorChrome.spaceSm,
              EditorChrome.spaceMd,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _StudioTabTile(
                      tab: _tabs[i],
                      selected: _index == i,
                      onTap: () => _onTabSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioTab {
  const _StudioTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _StudioTabTile extends StatelessWidget {
  const _StudioTabTile({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _StudioTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppTheme.matcha : AppTheme.muted;
    final labelColor = selected ? AppTheme.matcha : AppTheme.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? tab.selectedIcon : tab.icon,
              size: 22,
              color: iconColor,
            ),
            const SizedBox(height: 5),
            Text(
              tab.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
