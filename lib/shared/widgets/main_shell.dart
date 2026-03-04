import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../providers/budget_alert_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../../features/recurring/providers/recurring_check_provider.dart';

class MainShell extends ConsumerWidget {
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

  /// Navigates to [index] only if the user has set up a budget.
  /// Non-Home tabs are blocked until at least a daily limit is saved.
  void _onTabTap(BuildContext context, WidgetRef ref, int index) {
    if (index != 0) {
      final user = ref.read(userPreferencesNotifierProvider);
      final budgetReady = user != null && user.dailyLimit > 0;
      if (!budgetReady) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                  'Please set up your daily budget on the Home tab first.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        // Make sure the user is on Home so the setup prompt is visible.
        if (_currentIndex(context) != 0) context.go(AppRoutes.home);
        return;
      }
    }
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep these notifiers alive for the entire shell session.
    ref.watch(budgetAlertProvider);
    ref.watch(recurringCheckProvider);

    final user = ref.watch(userPreferencesNotifierProvider);
    final budgetReady = user != null && user.dailyLimit > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _currentIndex(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final navBg =
        isDark ? AppColors.darkNavBackground : AppColors.navBackground;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        if (isWide) {
          // ── Wide layout: NavigationRail on the left ─────────────────────────
          final isExtended = constraints.maxWidth >= 1200;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: navBg,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (i) => _onTabTap(context, ref, i),
                  extended: isExtended,
                  indicatorColor: Colors.transparent,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: const SizedBox(height: 8),
                  selectedIconTheme: IconThemeData(color: primaryColor),
                  unselectedIconTheme: IconThemeData(color: mutedColor),
                  selectedLabelTextStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                  destinations: _tabs.asMap().entries.map((e) {
                    final i = e.key;
                    final tab = e.value;
                    final isLocked = !budgetReady && i != 0;
                    return NavigationRailDestination(
                      icon: Opacity(
                        opacity: isLocked ? 0.35 : 1.0,
                        child: Icon(tab.inactiveIcon),
                      ),
                      selectedIcon: Icon(tab.activeIcon),
                      label: Opacity(
                        opacity: isLocked ? 0.35 : 1.0,
                        child: Text(tab.label),
                      ),
                    );
                  }).toList(),
                ),
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(child: child),
              ],
            ),
          );
        }

        // ── Narrow layout: bottom nav ─────────────────────────────────────────
        return Scaffold(
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: dividerColor, width: 1),
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
                    final isLocked = !budgetReady && index != 0;
                    final iconColor = isLocked
                        ? mutedColor.withAlpha(89)
                        : isActive
                            ? primaryColor
                            : mutedColor;
                    final textColor = isLocked
                        ? mutedColor.withAlpha(89)
                        : isActive
                            ? primaryColor
                            : mutedColor;

                    return Expanded(
                      child: InkWell(
                        onTap: () => _onTabTap(context, ref, index),
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
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isActive ? tab.activeIcon : tab.inactiveIcon,
                                  size: 24,
                                  color: iconColor,
                                ),
                                if (isLocked)
                                  Positioned(
                                    right: -6,
                                    bottom: -4,
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 11,
                                      color: mutedColor.withAlpha(128),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tab.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: textColor,
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
      },
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
