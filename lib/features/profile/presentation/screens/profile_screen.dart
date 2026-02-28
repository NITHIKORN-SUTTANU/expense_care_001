import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/widgets/app_card.dart';
import '../widgets/budget_limit_form.dart';
import '../widgets/theme_toggle.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── Mock state (replace with Riverpod providers) ─────────────────────────
  double _dailyLimit = 80.00;
  double? _weeklyLimit = 400.00;
  double? _monthlyLimit = 1200.00;
  bool _showWeekly = true;
  bool _showMonthly = true;
  bool _notificationsEnabled = true;
  final String _currency = 'USD';

  void _handleSaveLimits({
    required double daily,
    double? weekly,
    double? monthly,
    required bool showWeekly,
    required bool showMonthly,
  }) {
    setState(() {
      _dailyLimit = daily;
      _weeklyLimit = weekly;
      _monthlyLimit = monthly;
      _showWeekly = showWeekly;
      _showMonthly = showMonthly;
    });
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: FirebaseAuth.instance.signOut()
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkError
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkError
                    : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            title: Text(
              'Profile',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm + 80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── User Info ───────────────────────────────────────────
                _UserInfoSection(isDark: isDark),

                const SizedBox(height: AppSpacing.sm),

                // ── Budget Limits ────────────────────────────────────────
                _SectionLabel(label: 'Budget Limits', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: BudgetLimitForm(
                    dailyLimit: _dailyLimit,
                    weeklyLimit: _weeklyLimit,
                    monthlyLimit: _monthlyLimit,
                    showWeekly: _showWeekly,
                    showMonthly: _showMonthly,
                    onSave: _handleSaveLimits,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Preferences ──────────────────────────────────────────
                _SectionLabel(label: 'Preferences', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Currency
                      _ListTile(
                        label: 'Preferred Currency',
                        isDark: isDark,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currency,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: open currency picker modal
                        },
                        showDivider: true,
                      ),

                      // Theme
                      _ListTile(
                        label: 'Theme',
                        isDark: isDark,
                        trailing: ThemeToggle(
                          selectedMode: themeMode,
                          onChanged: (mode) {
                            ref.read(themeProvider.notifier).fromString(
                                  mode == ThemeMode.light
                                      ? 'light'
                                      : mode == ThemeMode.dark
                                          ? 'dark'
                                          : 'system',
                                );
                          },
                        ),
                        showDivider: true,
                      ),

                      // Show Weekly on Home
                      _ListTile(
                        label: 'Show Weekly Budget on Home',
                        isDark: isDark,
                        trailing: Switch(
                          value: _showWeekly,
                          onChanged: (val) => setState(() => _showWeekly = val),
                        ),
                        showDivider: true,
                      ),

                      // Show Monthly on Home
                      _ListTile(
                        label: 'Show Monthly Budget on Home',
                        isDark: isDark,
                        trailing: Switch(
                          value: _showMonthly,
                          onChanged: (val) =>
                              setState(() => _showMonthly = val),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Notifications ─────────────────────────────────────────
                _SectionLabel(label: 'Notifications', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: _ListTile(
                    label: 'Budget Alerts & Daily Reminder',
                    subtitle: 'Get notified at 80% and 100% of budget',
                    isDark: isDark,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),
                    showDivider: false,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── More ──────────────────────────────────────────────────
                _SectionLabel(label: 'More', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ListTile(
                        label: 'Recurring Expenses',
                        isDark: isDark,
                        leading:
                            const Text('🔁', style: TextStyle(fontSize: 20)),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                        onTap: () {
                          // TODO: context.push(AppRoutes.profileRecurring)
                        },
                        showDivider: true,
                      ),
                      _ListTile(
                        label: 'Export Data',
                        subtitle: 'Coming in v1.1',
                        isDark: isDark,
                        leading:
                            const Text('📊', style: TextStyle(fontSize: 20)),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                        enabled: false,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Account Actions ───────────────────────────────────────
                _SectionLabel(label: 'Account', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ListTile(
                        label: 'Sign Out',
                        isDark: isDark,
                        labelColor:
                            isDark ? AppColors.darkError : AppColors.error,
                        trailing: Icon(
                          Icons.logout_rounded,
                          color: isDark ? AppColors.darkError : AppColors.error,
                          size: 20,
                        ),
                        onTap: _handleSignOut,
                        showDivider: true,
                      ),
                      _ListTile(
                        label: 'Delete Account',
                        isDark: isDark,
                        labelColor:
                            (isDark ? AppColors.darkError : AppColors.error)
                                .withOpacity(0.7),
                        showDivider: false,
                        onTap: _handleDeleteAccount,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final primaryVariant =
        isDark ? AppColors.darkPrimaryVariant : AppColors.primaryVariant;

    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primaryVariant],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Name & email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alex Johnson',
                style: AppTextStyles.titleLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'alex@example.com',
                style: AppTextStyles.bodyMedium(
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),
            ],
          ),
        ),

        // Edit button
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(60, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: BorderSide(color: primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Edit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall(
          color: isDark ? AppColors.darkMuted : AppColors.muted,
        ).copyWith(letterSpacing: 0.9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.label,
    this.subtitle,
    required this.isDark,
    this.trailing,
    this.leading,
    this.onTap,
    this.labelColor,
    this.enabled = true,
    required this.showDivider,
  });

  final String label;
  final String? subtitle;
  final bool isDark;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? labelColor;
  final bool enabled;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final defaultColor =
        isDark ? AppColors.darkOnBackground : AppColors.onBackground;

    return Column(
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 14,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodyMedium(
                            color: labelColor ?? defaultColor,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.labelSmall(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.sm,
            endIndent: AppSpacing.sm,
            color: dividerColor,
          ),
      ],
    );
  }
}
