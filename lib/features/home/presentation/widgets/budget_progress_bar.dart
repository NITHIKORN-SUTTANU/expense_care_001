import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated horizontal progress bar for budget display.
/// Color transitions: success < 80%, warning 80-99%, error >= 100%
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.spentAmount,
    required this.budgetAmount,
    this.height = 8.0,
    this.animate = true,
  });

  final double spentAmount;
  final double budgetAmount;
  final double height;
  final bool animate;

  double get _percentage =>
      budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0;

  Color _barColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (budgetAmount <= 0)
      return isDark ? AppColors.darkSuccess : AppColors.success;
    final pct = spentAmount / budgetAmount * 100;
    if (pct >= 100) return isDark ? AppColors.darkError : AppColors.error;
    if (pct >= 80) return isDark ? AppColors.darkWarning : AppColors.warning;
    return isDark ? AppColors.darkSuccess : AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: AnimatedFractionallySizedBox(
            duration:
                animate ? const Duration(milliseconds: 800) : Duration.zero,
            curve: Curves.easeOutCubic,
            widthFactor: _percentage,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: _barColor(context),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
