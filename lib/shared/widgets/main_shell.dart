import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
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
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Active top-bar indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 20 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          isActive ? tab.activeIcon : tab.inactiveIcon,
                          size: 24,
                          color: isActive ? primaryColor : mutedColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
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
