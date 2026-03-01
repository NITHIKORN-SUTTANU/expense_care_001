import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/budget_limit_form.dart';
import '../widgets/theme_toggle.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _handleSaveLimits({
    required double daily,
    double? weekly,
    double? monthly,
    required bool showWeekly,
    required bool showMonthly,
  }) async {
    await ref.read(userPreferencesNotifierProvider.notifier).updateLimits(
          dailyLimit: daily,
          weeklyLimit: weekly,
          monthlyLimit: monthly,
          showWeeklyOnHome: showWeekly,
          showMonthlyOnHome: showMonthly,
        );
  }

  static const _currencies = [
    ('THB', 'Thai Baht', '฿'),
    ('USD', 'US Dollar', '\$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('CNY', 'Chinese Yuan', '¥'),
    ('KRW', 'Korean Won', '₩'),
    ('SGD', 'Singapore Dollar', 'S\$'),
    ('AUD', 'Australian Dollar', 'A\$'),
    ('CAD', 'Canadian Dollar', 'C\$'),
    ('CHF', 'Swiss Franc', 'Fr'),
    ('HKD', 'Hong Kong Dollar', 'HK\$'),
    ('INR', 'Indian Rupee', '₹'),
    ('MYR', 'Malaysian Ringgit', 'RM'),
    ('IDR', 'Indonesian Rupiah', 'Rp'),
    ('PHP', 'Philippine Peso', '₱'),
    ('VND', 'Vietnamese Dong', '₫'),
  ];

  void _showCurrencyPicker(String currentCurrency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheetTop),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: Text(
                'Select Currency',
                style: AppTextStyles.titleLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
            ),
            Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.divider),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currencies.length,
                itemBuilder: (ctx, i) {
                  final (code, name, symbol) = _currencies[i];
                  final selected = code == currentCurrency;
                  final primary =
                      isDark ? AppColors.darkPrimary : AppColors.primary;
                  return ListTile(
                    onTap: () {
                      if (selected) {
                        Navigator.pop(ctx);
                        return;
                      }
                      showDialog(
                        context: ctx,
                        useRootNavigator: false,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Change Currency?'),
                          content: Text(
                            'Existing expenses won\'t be converted — '
                            'numbers stay the same with the new $name ($code) symbol. '
                            'You should also update your budget limits.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(userPreferencesNotifierProvider
                                        .notifier)
                                    .updateCurrency(code);
                                Navigator.pop(dialogCtx);
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                'Change to $code',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? primary.withValues(alpha: 0.12)
                            : (isDark
                                ? AppColors.darkBackground
                                : AppColors.background),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? primary : (isDark ? AppColors.darkOnBackground : AppColors.onBackground),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.darkOnBackground
                            : AppColors.onBackground,
                      ).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                    ),
                    subtitle: Text(
                      code,
                      style: AppTextStyles.labelSmall(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_rounded, color: primary, size: 20)
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Future.delayed(Duration.zero);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(dialogContext).brightness == Brightness.dark
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
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(dialogContext).brightness == Brightness.dark
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
    final user = ref.watch(userPreferencesNotifierProvider);

    final dailyLimit = user?.dailyLimit ?? 0.0;
    final weeklyLimit = user?.weeklyLimit;
    final monthlyLimit = user?.monthlyLimit;
    final showWeekly = user?.showWeeklyOnHome ?? false;
    final showMonthly = user?.showMonthlyOnHome ?? false;
    final currency = user?.preferredCurrency ?? 'USD';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            titleSpacing: 20,
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
              20,
              AppSpacing.sm,
              20,
              AppSpacing.sm + 80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── User Info ───────────────────────────────────────────
                _UserInfoSection(isDark: isDark, user: user),

                const SizedBox(height: AppSpacing.sm),

                // ── Budget Limits ────────────────────────────────────────
                _SectionLabel(label: 'Budget Limits', isDark: isDark),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: BudgetLimitForm(
                    dailyLimit: dailyLimit,
                    weeklyLimit: weeklyLimit,
                    monthlyLimit: monthlyLimit,
                    showWeekly: showWeekly,
                    showMonthly: showMonthly,
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
                              currency,
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
                        onTap: () => _showCurrencyPicker(currency),
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
                          value: showWeekly,
                          onChanged: (val) => ref
                              .read(userPreferencesNotifierProvider.notifier)
                              .updateLimits(
                                dailyLimit: dailyLimit,
                                weeklyLimit: weeklyLimit,
                                monthlyLimit: monthlyLimit,
                                showWeeklyOnHome: val,
                                showMonthlyOnHome: showMonthly,
                              ),
                        ),
                        showDivider: true,
                      ),

                      // Show Monthly on Home
                      _ListTile(
                        label: 'Show Monthly Budget on Home',
                        isDark: isDark,
                        trailing: Switch(
                          value: showMonthly,
                          onChanged: (val) => ref
                              .read(userPreferencesNotifierProvider.notifier)
                              .updateLimits(
                                dailyLimit: dailyLimit,
                                weeklyLimit: weeklyLimit,
                                monthlyLimit: monthlyLimit,
                                showWeeklyOnHome: showWeekly,
                                showMonthlyOnHome: val,
                              ),
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
                        onTap: () => context.push(AppRoutes.profileRecurring),
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
                                .withValues(alpha: 0.7),
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
  const _UserInfoSection({required this.isDark, this.user});
  final bool isDark;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final initials = (user?.displayName.isNotEmpty == true)
        ? user!.displayName[0].toUpperCase()
        : '?';

    return Row(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
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
                user?.displayName ?? '—',
                style: AppTextStyles.titleLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? '—',
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
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
