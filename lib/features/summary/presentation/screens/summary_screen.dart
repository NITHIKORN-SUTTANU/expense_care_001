import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../../../expense/data/expense_repository.dart';
import '../../../expense/domain/models/category_model.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../../expense/presentation/screens/add_expense_screen.dart';
import '../../../../../shared/utils/expense_actions.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  static const _periods = ['Day', 'Week', 'Month', 'Custom'];

  int _selectedPeriod = 2; // default: Month
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _customIsRange = false;

  // ── Date range computation ─────────────────────────────────────────────────

  DateRangeKey get _activeKey {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0:
        return DateRangeKey(
            AppDateUtils.startOfDay(now), AppDateUtils.endOfDay(now));
      case 1:
        return DateRangeKey(
            AppDateUtils.startOfWeek(now), AppDateUtils.endOfDay(now));
      case 3:
        if (_customStart != null) {
          if (_customIsRange && _customEnd != null) {
            return DateRangeKey(_customStart!, _customEnd!);
          } else if (!_customIsRange) {
            return DateRangeKey(AppDateUtils.startOfDay(_customStart!),
                AppDateUtils.endOfDay(_customStart!));
          }
        }
        // fallback while picker is open
        return DateRangeKey(
            AppDateUtils.startOfMonth(now), AppDateUtils.endOfDay(now));
      default: // 2 = Month
        return DateRangeKey(
            AppDateUtils.startOfMonth(now), AppDateUtils.endOfMonth(now));
    }
  }

  String get _rangeLabel {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0:
        return DateFormat('EEE, MMM d, y').format(now);
      case 1:
        final weekStart = AppDateUtils.startOfWeek(now);
        final startStr = weekStart.year == now.year
            ? DateFormat('MMM d').format(weekStart)
            : DateFormat('MMM d, y').format(weekStart);
        return '$startStr – ${DateFormat('MMM d, y').format(now)}';
      case 2:
        return DateFormat('MMMM y').format(now);
      case 3:
        if (_customStart != null) {
          if (!_customIsRange) {
            return DateFormat('EEE, d MMM y').format(_customStart!);
          }
          if (_customEnd != null) {
            final startStr = _customStart!.year == _customEnd!.year
                ? DateFormat('MMM d').format(_customStart!)
                : DateFormat('MMM d, y').format(_customStart!);
            return '$startStr – ${DateFormat('MMM d, y').format(_customEnd!)}';
          }
        }
        return 'Selecting…';
      default:
        return '';
    }
  }

  // ── Custom period picker ───────────────────────────────────────────────────

  Future<void> _pickCustom() async {
    final result = await showAppCustomPeriodPicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialIsRange: _customIsRange,
      initialStart: _customStart,
      initialEnd: _customEnd,
    );
    if (!mounted) return;
    if (result == null) {
      // Dismissed without confirming — always stay on the Custom tab.
    } else {
      setState(() {
        _customIsRange = result.isRange;
        _customStart = AppDateUtils.startOfDay(result.start);
        _customEnd =
            result.end != null ? AppDateUtils.endOfDay(result.end!) : null;
      });
    }
  }

  void _onPeriodTap(int i) {
    if (i == 3) {
      setState(() => _selectedPeriod = 3);
      _pickCustom();
    } else {
      setState(() {
        _selectedPeriod = i;
        _customStart = null;
        _customEnd = null;
        _customIsRange = false;
      });
    }
  }

  void _openCategoryDetail(BuildContext context, _CatSummary cat) {
    showAppBottomSheet(
      context: context,
      title: cat.name,
      child: _CategoryExpensesSheet(
        categoryId: cat.categoryId,
        dateRangeKey: _activeKey,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final currency =
        ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';

    final expensesAsync = ref.watch(expensesByDateRangeProvider(_activeKey));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: surfaceColor,
            titleSpacing: 20,
            title: Text(
              'Summary',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: borderColor),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                20, AppSpacing.sm, 20, AppSpacing.sm + 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Period tabs
                _PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  periods: _periods,
                  isDark: isDark,
                  onTap: _onPeriodTap,
                ),

                // Active range label — tappable when Custom is active so the
                // user can adjust the selection without re-tapping the tab.
                const SizedBox(height: AppSpacing.xxs),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _selectedPeriod == 3 ? _pickCustom : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _rangeLabel,
                          style: AppTextStyles.labelSmall(
                            color: _selectedPeriod == 3
                                ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary)
                                : (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.muted),
                          ),
                        ),
                        if (_selectedPeriod == 3) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Data
                if (_selectedPeriod == 3 && _customStart == null)
                  const _CustomPickPrompt()
                else
                  expensesAsync.when(
                    loading: () => const _LoadingBody(),
                    error: (_, __) => const _ErrorBody(),
                    data: (expenses) => expenses.isEmpty
                        ? const _EmptyBody()
                        : _SummaryBody(
                            expenses: expenses,
                            currency: currency,
                            isDark: isDark,
                            borderColor: borderColor,
                            surfaceColor: surfaceColor,
                            onCategoryTap: (cat) =>
                                _openCategoryDetail(context, cat),
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

// ── Period Selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.periods,
    required this.isDark,
    required this.onTap,
  });

  final int selectedPeriod;
  final List<String> periods;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.chip + 4),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: List.generate(periods.length, (i) {
          final isSelected = selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  periods[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Summary Body ──────────────────────────────────────────────────────────────

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.expenses,
    required this.currency,
    required this.isDark,
    required this.borderColor,
    required this.surfaceColor,
    required this.onCategoryTap,
  });

  final List<ExpenseModel> expenses;
  final String currency;
  final bool isDark;
  final Color borderColor;
  final Color surfaceColor;
  final ValueChanged<_CatSummary> onCategoryTap;

  double get _total =>
      expenses.fold(0.0, (acc, e) => acc + e.amountInBaseCurrency);

  double get _largest =>
      expenses.map((e) => e.amountInBaseCurrency).reduce(max);

  List<_CatSummary> _buildCategories(double total) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amountInBaseCurrency;
    }
    return (map.entries.map((entry) {
      final cat = CategoryModel.findById(entry.key);
      return _CatSummary(
        categoryId: entry.key,
        name: cat?.name ?? 'Other',
        icon: cat?.icon ?? Icons.category_rounded,
        color: cat?.color ?? AppColors.catOther,
        amount: entry.value,
        pct: total > 0 ? (entry.value / total * 100) : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount)));
  }

  String _fmt(double v) =>
      NumberFormat.simpleCurrency(name: currency, decimalDigits: 2).format(v);

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final cats = _buildCategories(total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats bar
        _StatsBar(
          total: _fmt(total),
          count: expenses.length.toString(),
          largest: _fmt(_largest),
          isDark: isDark,
          borderColor: borderColor,
          surfaceColor: surfaceColor,
        ),

        const SizedBox(height: AppSpacing.md),

        // Donut chart
        _DonutChart(
          categories: cats,
          total: total,
          currency: currency,
          isDark: isDark,
        ),

        const SizedBox(height: AppSpacing.md),

        // Category breakdown
        _CategoryList(
          categories: cats,
          currency: currency,
          isDark: isDark,
          borderColor: borderColor,
          surfaceColor: surfaceColor,
          onCategoryTap: onCategoryTap,
        ),
      ],
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.total,
    required this.count,
    required this.largest,
    required this.isDark,
    required this.borderColor,
    required this.surfaceColor,
  });

  final String total;
  final String count;
  final String largest;
  final bool isDark;
  final Color borderColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(label: 'Total Spent', value: total, isDark: isDark),
            VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
                indent: 4,
                endIndent: 4),
            _StatCell(label: 'Transactions', value: count, isDark: isDark),
            VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
                indent: 4,
                endIndent: 4),
            _StatCell(label: 'Largest', value: largest, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

// ── Donut Chart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.categories,
    required this.total,
    required this.currency,
    required this.isDark,
  });

  final List<_CatSummary> categories;
  final double total;
  final String currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sections = categories
        .map((cat) => PieChartSectionData(
              color: cat.color,
              value: cat.amount,
              title: '',
              radius: 36,
              showTitle: false,
            ))
        .toList();

    final formattedTotal =
        NumberFormat.simpleCurrency(name: currency, decimalDigits: 0)
            .format(total);

    return Center(
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 69,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTotal,
                  style: AppTextStyles.titleLarge(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
                Text(
                  'total',
                  style: AppTextStyles.labelSmall(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category List ─────────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.currency,
    required this.isDark,
    required this.borderColor,
    required this.surfaceColor,
    required this.onCategoryTap,
  });

  final List<_CatSummary> categories;
  final String currency;
  final bool isDark;
  final Color borderColor;
  final Color surfaceColor;
  final ValueChanged<_CatSummary> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          children: categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final isLast = i == categories.length - 1;
            final formatted =
                NumberFormat.simpleCurrency(name: currency, decimalDigits: 2)
                    .format(cat.amount);

            return Column(
              children: [
                InkWell(
                  onTap: () => onCategoryTap(cat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Icon box
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Icon(cat.icon, size: 18, color: cat.color),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name + progress bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: AppTextStyles.labelLarge(
                                  color: isDark
                                      ? AppColors.darkOnBackground
                                      : AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: cat.pct / 100,
                                  backgroundColor: isDark
                                      ? AppColors.darkDivider
                                      : AppColors.divider,
                                  color: cat.color,
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Amount + percentage + chevron
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatted,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkOnBackground
                                    : AppColors.onBackground,
                              ),
                            ),
                            Text(
                              '${cat.pct.toStringAsFixed(0)}%',
                              style: AppTextStyles.labelSmall(
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: borderColor,
                    indent: 66,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Category Expenses Sheet ───────────────────────────────────────────────────

class _CategoryExpensesSheet extends ConsumerStatefulWidget {
  const _CategoryExpensesSheet({
    required this.categoryId,
    required this.dateRangeKey,
  });

  final String categoryId;
  final DateRangeKey dateRangeKey;

  @override
  ConsumerState<_CategoryExpensesSheet> createState() =>
      _CategoryExpensesSheetState();
}

class _CategoryExpensesSheetState
    extends ConsumerState<_CategoryExpensesSheet> {
  // ── Delete helpers ──────────────────────────────────────────────────────────

  /// Deletes [expense] from Firestore.
  /// For savings expenses linked to a goal, also decrements goal progress.
  Future<void> _deleteExpense(ExpenseModel expense) async {
    try {
      await deleteExpenseAndSync(expense, ref.read(expenseRepositoryProvider));
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to delete. Please try again.');
      }
    }
  }

  /// Shows the canonical delete confirmation and returns true if confirmed.
  Future<bool?> _confirmDelete(ExpenseModel expense) =>
      showExpenseDeleteDialog(context, expense);

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final currency =
        ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 2);

    final allExpenses = ref
            .watch(expensesByDateRangeProvider(widget.dateRangeKey))
            .valueOrNull ??
        [];
    final expenses = allExpenses
        .where((e) => e.categoryId == widget.categoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Text(
            'No expenses in this category for the selected period.',
            style: AppTextStyles.bodyMedium(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Header summary row
    final total = expenses.fold(0.0, (acc, e) => acc + e.amountInBaseCurrency);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mini stats
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xxs, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Text(
                '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                style: AppTextStyles.labelSmall(
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),
              const Spacer(),
              Text(
                fmt.format(total),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),

        // Expense list
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xs,
            ),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: borderColor,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
            itemBuilder: (ctx, i) {
              final expense = expenses[i];
              final cat = CategoryModel.findById(expense.categoryId);
              final title = expense.note?.isNotEmpty == true
                  ? expense.note!
                  : (cat?.name ?? '—');

              final rowContent = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Date column
                    SizedBox(
                      width: 52,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d').format(expense.date),
                            style: AppTextStyles.labelLarge(
                              color: isDark
                                  ? AppColors.darkOnBackground
                                  : AppColors.onBackground,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(expense.date),
                            style: AppTextStyles.labelSmall(
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Note
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium(
                          color: isDark
                              ? AppColors.darkOnBackground
                              : AppColors.onBackground,
                        ).copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Amount + edit hint
                    Text(
                      fmt.format(expense.amountInBaseCurrency),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkOnBackground
                            : AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ],
                ),
              );

              // Tap handler: recurring → same delete dialog as swipe;
              // regular / savings → open edit sheet.
              void onTap() {
                if (expense.isRecurring) {
                  showExpenseDeleteDialog(context, expense)
                      .then((confirmed) async {
                    if (confirmed != true || !mounted) return;
                    await _deleteExpense(expense);
                  });
                } else {
                  showAppBottomSheet(
                    context: context,
                    title: 'Edit Expense',
                    child: AddExpenseScreen(expense: expense),
                  );
                }
              }

              return Dismissible(
                key: ValueKey(expense.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  color: (isDark ? AppColors.darkError : AppColors.error)
                      .withValues(alpha: 0.12),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: isDark ? AppColors.darkError : AppColors.error,
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(expense),
                onDismissed: (_) => _deleteExpense(expense),
                child: InkWell(
                  onTap: onTap,
                  child: rowContent,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Empty / Loading / Error states ────────────────────────────────────────────

class _CustomPickPrompt extends StatelessWidget {
  const _CustomPickPrompt();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.edit_calendar_rounded,
            size: 56,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No date selected',
            style: AppTextStyles.titleMedium(
              color:
                  isDark ? AppColors.darkOnBackground : AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the calendar icon above to pick a date or range.',
            style: AppTextStyles.bodyMedium(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 56,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No expenses for this period',
            style: AppTextStyles.titleMedium(
              color:
                  isDark ? AppColors.darkOnBackground : AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add expenses to see your spending breakdown.',
            style: AppTextStyles.bodyMedium(
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'Failed to load data. Please try again.',
          style: AppTextStyles.bodyMedium(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _CatSummary {
  const _CatSummary({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.pct,
  });

  final String categoryId;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double pct;
}
