import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budget_progress_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Two compact cards for weekly and monthly budgets.
/// Only shown when user has enabled them in Profile.
class OptionalBudgetCards extends StatelessWidget {
  const OptionalBudgetCards({
    super.key,
    required this.weeklySpent,
    required this.weeklyBudget,
    required this.monthlySpent,
    required this.monthlyBudget,
    required this.showWeekly,
    required this.showMonthly,
    required this.currency,
  });

  final double weeklySpent;
  final double weeklyBudget;
  final double monthlySpent;
  final double monthlyBudget;
  final bool showWeekly;
  final bool showMonthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (!showWeekly && !showMonthly) return const SizedBox.shrink();

    return Row(
      children: [
        if (showWeekly)
          Expanded(
            child: _MiniCard(
              label: 'Weekly',
              spent: weeklySpent,
              budget: weeklyBudget,
            ),
          ),
        if (showWeekly && showMonthly) const SizedBox(width: AppSpacing.xs),
        if (showMonthly)
          Expanded(
            child: _MiniCard(
              label: 'Monthly',
              spent: monthlySpent,
              budget: monthlyBudget,
            ),
          ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.spent,
    required this.budget,
  });

  final String label;
  final double spent;
  final double budget;

  String _fmt(double v) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = budget - spent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
        boxShadow: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ).copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(remaining.abs()),
            style: AppTextStyles.titleLarge(
              color: remaining < 0
                  ? (isDark ? AppColors.darkError : AppColors.error)
                  : (isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground),
            ),
          ),
          const SizedBox(height: 8),
          BudgetProgressBar(
              spentAmount: spent, budgetAmount: budget, height: 6),
          const SizedBox(height: 6),
          Text(
            '${_fmt(spent)} / ${_fmt(budget)}',
            style: AppTextStyles.labelSmall(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
