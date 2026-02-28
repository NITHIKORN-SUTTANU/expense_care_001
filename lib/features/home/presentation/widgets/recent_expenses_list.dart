import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../../expense/domain/models/category_model.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_colors.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Expenses',
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (expenses.isEmpty)
          _EmptyState(isDark: isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _ExpenseRow(
                expense: expenses[index],
                isDark: isDark,
                onTap: () => onExpenseTap?.call(expenses[index]),
              );
            },
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(expense.date);
  }

  String _formatAmount() {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2)
        .format(expense.amountInBaseCurrency);
  }

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.findById(expense.categoryId);
    final catColor = category?.color ?? AppColors.catOther;
    final catEmoji = category?.emoji ?? '📦';
    final catName = category?.name ?? 'Other';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Category icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(catEmoji, style: const TextStyle(fontSize: 22)),
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

          const SizedBox(width: 8),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_formatAmount()}',
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              if (!expense.syncedToFirestore)
                const Icon(Icons.cloud_upload_outlined,
                    size: 14, color: AppColors.muted),
            ],
          ),
        ],
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
              'Start tracking your spending!',
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
