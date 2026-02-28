import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budget_progress_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Priority component on Home screen.
/// Shows remaining daily budget, spent vs total, animated progress bar.
class DailyBudgetCard extends StatelessWidget {
  const DailyBudgetCard({
    super.key,
    required this.spent,
    required this.budget,
    required this.currency,
  });

  final double spent;
  final double budget;
  final String currency;

  double get _remaining => budget - spent;
  bool get _isOverBudget => _remaining < 0;
  double get _pct => budget > 0 ? (spent / budget * 100) : 0;

  Color _statusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_pct >= 100) return isDark ? AppColors.darkError : AppColors.error;
    if (_pct >= 80) return isDark ? AppColors.darkWarning : AppColors.warning;
    return isDark ? AppColors.darkSuccess : AppColors.success;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final error = isDark ? AppColors.darkError : AppColors.error;
    final statusColor = _statusColor(context);

    final bgGradientColor =
        _isOverBudget ? error.withOpacity(0.08) : primary.withOpacity(0.06);
    final borderColor =
        _isOverBudget ? error.withOpacity(0.3) : primary.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgGradientColor,
            isDark ? AppColors.darkSurface : AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: (primary).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Budget',
                    style: AppTextStyles.labelSmall(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ).copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(_remaining.abs()),
                    style: AppTextStyles.displayLarge(
                      color: _isOverBudget
                          ? error
                          : isDark
                              ? AppColors.darkOnBackground
                              : AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOverBudget
                        ? 'Over budget by ${_formatCurrency(_remaining.abs())}'
                        : 'remaining today',
                    style: AppTextStyles.bodyMedium(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '${_pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          BudgetProgressBar(
            spentAmount: spent,
            budgetAmount: budget,
            height: 8,
          ),

          const SizedBox(height: 10),

          // Spent / Limit row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatText(
                label: 'Spent',
                value: _formatCurrency(spent),
                isDark: isDark,
              ),
              _StatText(
                label: 'Limit',
                value: _formatCurrency(budget),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkMuted : AppColors.muted,
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
