import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(
        label: 'Home',
        route: AppRoutes.home,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined),
    _TabItem(
        label: 'Goals',
        route: AppRoutes.goals,
        activeIcon: Icons.flag_rounded,
        inactiveIcon: Icons.flag_outlined),
    _TabItem(
        label: 'Summary',
        route: AppRoutes.summary,
        activeIcon: Icons.bar_chart_rounded,
        inactiveIcon: Icons.bar_chart_outlined),
    _TabItem(
        label: 'Profile',
        route: AppRoutes.profile,
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outline_rounded),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.goals)) return 1;
    if (location.startsWith(AppRoutes.summary)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNavBackground : AppColors.navBackground,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4))
                ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isActive = currentIndex == index;
                final primaryColor =
                    isDark ? AppColors.darkPrimary : AppColors.primary;
                final mutedColor =
                    isDark ? AppColors.darkMuted : AppColors.muted;

                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(tab.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.inactiveIcon,
                            size: 22,
                            color: isActive ? primaryColor : mutedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? primaryColor : mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(
      {required this.label,
      required this.route,
      required this.activeIcon,
      required this.inactiveIcon});
  final String label;
  final String route;
  final IconData activeIcon;
  final IconData inactiveIcon;
}
