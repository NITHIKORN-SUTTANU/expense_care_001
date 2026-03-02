import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expense/domain/models/category_model.dart';
import '../../../expense/presentation/widgets/category_selector.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../recurring/domain/models/recurring_expense_model.dart';

// ── Firestore provider ────────────────────────────────────────────────────────

final recurringProvider =
    StreamProvider<List<RecurringExpenseModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('recurring')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => RecurringExpenseModel.fromMap(d.data(), d.id)).toList());
});

// ── Screen ────────────────────────────────────────────────────────────────────

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(recurringProvider).valueOrNull ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            titleSpacing: 4,
            title: Text(
              'Recurring Expenses',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _openAddSheet(context),
                tooltip: 'Add Recurring',
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
          ),

          if (items.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                emoji: '🔁',
                title: 'No recurring expenses',
                subtitle: 'Set one up to automate your tracking.',
                actionLabel: 'Add Recurring',
                onAction: () => _openAddSheet(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  20, AppSpacing.sm, 20, AppSpacing.sm + 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _RecurringCard(
                      item: items[i],
                      isDark: isDark,
                      onDelete: () => _delete(ref, items[i]),
                    ),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, RecurringExpenseModel item) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recurring')
        .doc(item.id)
        .delete();
  }
}

// ── Recurring card ────────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.isDark,
    required this.onDelete,
  });

  final RecurringExpenseModel item;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = CategoryModel.findById(item.categoryId);
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final isOverdue = !item.nextDueDate.isAfter(DateTime.now());

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkError : AppColors.error)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: isDark ? AppColors.darkError : AppColors.error,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Recurring Expense'),
            content: Text('Remove "${item.name}" from recurring expenses?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: isDark ? AppColors.darkError : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  cat?.emoji ?? '📦',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Name + next due
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.labelLarge(
                      color: isDark
                          ? AppColors.darkOnBackground
                          : AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _FrequencyBadge(
                        label: item.frequencyLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due ${DateFormat('MMM d').format(item.nextDueDate)}',
                        style: AppTextStyles.labelSmall(
                          color: isOverdue
                              ? (isDark
                                  ? AppColors.darkError
                                  : AppColors.error)
                              : (isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              NumberFormat.simpleCurrency(name: item.currency)
                  .format(item.amount),
              style: AppTextStyles.labelLarge(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(color: color)
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Add Recurring bottom sheet ────────────────────────────────────────────────

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategoryId;
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _isSaving = false;

  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('yearly', 'Yearly'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final currency =
        ref.read(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final amount =
          double.parse(_amountCtrl.text.replaceAll(',', ''));

      final recurring = RecurringExpenseModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: uid,
        name: _nameCtrl.text.trim(),
        amount: amount,
        currency: currency,
        categoryId: _selectedCategoryId!,
        frequency: _frequency,
        startDate: _startDate,
        nextDueDate: _startDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: now,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recurring')
          .doc(recurring.id)
          .set(recurring.toMap());

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final currency =
        ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final currencySymbol =
        NumberFormat.simpleCurrency(name: currency).currencySymbol;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: divColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'New Recurring Expense',
                style: AppTextStyles.titleLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Name ──────────────────────────────────────────────────
              AppTextField(
                controller: _nameCtrl,
                label: 'Name',
                hint: 'e.g. Netflix, Rent',
                validator: Validators.recurringName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Amount ────────────────────────────────────────────────
              AppTextField(
                controller: _amountCtrl,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixText: '$currencySymbol ',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: (v) =>
                    Validators.requiredPositiveNumber(v, label: 'Amount'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Category ──────────────────────────────────────────────
              Text(
                'Category',
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              CategorySelector(
                selectedId: _selectedCategoryId,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Frequency ─────────────────────────────────────────────
              Text(
                'Frequency',
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: _frequencies.map((entry) {
                  final (value, label) = entry;
                  final selected = _frequency == value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _frequency = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.chip + 2),
                          border: Border.all(
                            color: selected ? primary : divColor,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall(
                            color: selected ? primary : muted,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Start Date ────────────────────────────────────────────
              Text(
                'Start Date',
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.darkOnBackground
                      : AppColors.onBackground,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: divColor),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: muted),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(_startDate),
                        style: AppTextStyles.bodyMedium(
                          color: isDark
                              ? AppColors.darkOnBackground
                              : AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Note ──────────────────────────────────────────────────
              AppTextField(
                controller: _noteCtrl,
                label: 'Note (optional)',
                hint: 'e.g. Family plan',
                maxLength: 200,
                textInputAction: TextInputAction.done,
                validator: Validators.note,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Save ──────────────────────────────────────────────────
              AppButton(
                label: 'Save',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
