import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return NumberFormat.simpleCurrency(name: currency, decimalDigits: 2)
        .format(amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = isDark ? AppColors.darkError : AppColors.error;
    final statusColor = _statusColor(context);
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'DAILY BUDGET',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Hero row: remaining amount + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCurrency(_remaining.abs()),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: _isOverBudget
                          ? error
                          : isDark
                              ? AppColors.darkOnBackground
                              : AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOverBudget ? 'over budget today' : 'remaining today',
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOverBudget ? 'Over limit' : '${_pct.floor()}% used',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          BudgetProgressBar(
            spentAmount: spent,
            budgetAmount: budget,
            height: 6,
          ),

          const SizedBox(height: AppSpacing.xs + 2),

          // Spent / Limit stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatLabel(
                label: 'Spent',
                value: _formatCurrency(spent),
                isDark: isDark,
              ),
              _StatLabel(
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

class _StatLabel extends StatelessWidget {
  const _StatLabel({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
