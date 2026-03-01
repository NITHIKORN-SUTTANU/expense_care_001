import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../../expense/domain/models/category_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class RecentExpensesList extends StatelessWidget {
  const RecentExpensesList({
    super.key,
    required this.expenses,
    this.onSeeAll,
    this.onExpenseTap,
  });

  final List<ExpenseModel> expenses;
  final VoidCallback? onSeeAll;
  final ValueChanged<ExpenseModel>? onExpenseTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recent',
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: const Size(48, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        if (expenses.isEmpty)
          _EmptyState(isDark: isDark)
        else
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                  indent: 68,
                ),
                itemBuilder: (context, index) {
                  return _ExpenseRow(
                    expense: expenses[index],
                    isDark: isDark,
                    onTap: () => onExpenseTap?.call(expenses[index]),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.isDark,
    this.onTap,
  });

  final ExpenseModel expense;
  final bool isDark;
  final VoidCallback? onTap;

  String _relativeTime() {
    final now = DateTime.now();
    final diff = now.difference(expense.date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(expense.date);
  }

  String _formatAmount() {
    return NumberFormat.simpleCurrency(name: expense.currency, decimalDigits: 2)
        .format(expense.amountInBaseCurrency);
  }

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.findById(expense.categoryId);
    final catColor = category?.color ?? AppColors.catOther;
    final catEmoji = category?.emoji ?? '📦';
    final catName = category?.name ?? 'Other';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(catEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(width: 12),

            // Name + category + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.note?.isNotEmpty == true ? expense.note! : catName,
                    style: AppTextStyles.labelLarge(
                      color: isDark
                          ? AppColors.darkOnBackground
                          : AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$catName · ${_relativeTime()}',
                    style: AppTextStyles.labelSmall(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            // Amount
            Text(
              '-${_formatAmount()}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text('💸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No expenses yet.',
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start tracking your spending.',
              style: AppTextStyles.bodyMedium(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
