import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expense/domain/models/category_model.dart';
import '../../../expense/presentation/widgets/category_selector.dart';
import '../../../recurring/data/recurring_repository.dart';
import '../../../recurring/domain/models/recurring_expense_model.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  void _openSheet(BuildContext context, {RecurringExpenseModel? item}) {
    showAppBottomSheet(
      context: context,
      title: item == null ? 'New Recurring Expense' : 'Edit Recurring Expense',
      child: _RecurringFormSheet(item: item),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseModel item,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recurring')
          .doc(item.id)
          .delete();
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Failed to delete. Please try again.');
      }
    }
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
                onPressed: () => _openSheet(context),
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
                icon: Icons.repeat_rounded,
                title: 'No recurring expenses',
                subtitle: 'Set one up to automate your tracking.',
                actionLabel: 'Add Recurring',
                onAction: () => _openSheet(context),
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
                      onEdit: () => _openSheet(context, item: items[i]),
                      onDelete: () => _delete(context, ref, items[i]),
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
}

// ── Recurring card ────────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpenseModel item;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = CategoryModel.findById(item.categoryId);
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
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
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: item.isActive ? borderColor : borderColor.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category icon avatar
                Opacity(
                  opacity: item.isActive ? 1.0 : 0.4,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        cat?.icon ?? Icons.category_rounded,
                        size: 22,
                        color: primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Name + frequency badge (middle, expands)
                Expanded(
                  child: Opacity(
                    opacity: item.isActive ? 1.0 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + paused badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTextStyles.labelLarge(
                                  color: isDark
                                      ? AppColors.darkOnBackground
                                      : AppColors.onBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: muted.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'Paused',
                                  style: AppTextStyles.labelSmall(color: muted)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Frequency badge only
                        _FrequencyBadge(
                          label: item.frequencyLabel,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Right column: amount (top) + due date (bottom)
                Opacity(
                  opacity: item.isActive ? 1.0 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Amount
                      Text(
                        NumberFormat.simpleCurrency(name: item.currency)
                            .format(item.amount),
                        style: AppTextStyles.labelLarge(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Due date
                      Text(
                        item.isActive
                            ? 'Due ${DateFormat('d MMM yyyy').format(item.nextDueDate)}'
                            : '—',
                        style: AppTextStyles.labelSmall(
                          color: isOverdue && item.isActive
                              ? (isDark
                                  ? AppColors.darkError
                                  : AppColors.error)
                              : muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

// ── Recurring form sheet (Add & Edit) ─────────────────────────────────────────

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({this.item});
  final RecurringExpenseModel? item;

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  late String? _selectedCategoryId;
  late String _frequency;
  late DateTime _startDate;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('yearly', 'Yearly'),
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.item;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _amountCtrl = TextEditingController(
      text: g != null
          ? g.amount.toStringAsFixed(
              g.amount == g.amount.truncate() ? 0 : 2)
          : '',
    );
    _noteCtrl = TextEditingController(text: g?.note ?? '');
    _selectedCategoryId = g?.categoryId;
    _frequency = g?.frequency ?? 'monthly';
    _startDate = g?.startDate ?? DateTime.now();
    _isActive = g?.isActive ?? true;
  }

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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Expense'),
        content: Text('Remove "${widget.item!.name}" from recurring expenses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.darkError
                    : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recurring')
          .doc(widget.item!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'Failed to delete. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      showErrorSnackBar(context, 'Please select a category.');
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final currency =
        ref.read(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      // Normalize to midnight so expense IDs (based on due.millisecondsSinceEpoch)
      // are always the same for a given calendar date — prevents duplicates on resume.
      final today = DateTime(now.year, now.month, now.day);

      if (_isEditing) {
        // Only update mutable fields — createdAt stays unchanged.
        // On resume: reset nextDueDate to midnight today. The check provider
        // uses SetOptions(merge: false) with a deterministic date-based ID, so
        // the existing expense doc is overwritten rather than duplicated.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('recurring')
            .doc(widget.item!.id)
            .update({
          'name': _nameCtrl.text.trim(),
          'amount': amount,
          'categoryId': _selectedCategoryId,
          'frequency': _frequency,
          'startDate': _startDate.toIso8601String(),
          'note': note,
          'isActive': _isActive,
          if (!widget.item!.isActive && _isActive)
            'nextDueDate': today.toIso8601String(),
        });

        // Propagate changed fields to every expense document that was
        // generated from this recurring item (identified by recurringId).
        // Dates are intentionally left unchanged — past records stay accurate.
        final expSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .where('recurringId', isEqualTo: widget.item!.id)
            .get();

        if (expSnap.docs.isNotEmpty) {
          final expNote = note ?? _nameCtrl.text.trim();
          // Commit in chunks of 490 to stay under Firestore's 500-op limit.
          const kChunk = 490;
          final docs = expSnap.docs;
          for (var i = 0; i < docs.length; i += kChunk) {
            final chunk = docs.sublist(
                i, (i + kChunk).clamp(0, docs.length));
            final expBatch = FirebaseFirestore.instance.batch();
            for (final doc in chunk) {
              expBatch.update(doc.reference, {
                'amount': amount,
                'amountInBaseCurrency': amount,
                'categoryId': _selectedCategoryId,
                'note': expNote,
              });
            }
            await expBatch.commit();
          }
        }
      } else {
        final recurring = RecurringExpenseModel(
          id: now.millisecondsSinceEpoch.toString(),
          userId: uid,
          name: _nameCtrl.text.trim(),
          amount: amount,
          currency: currency,
          categoryId: _selectedCategoryId!,
          frequency: _frequency,
          startDate: _startDate,
          // Normalize to midnight so expense IDs are date-deterministic.
          // Past start date → track from today; future → use that date at midnight.
          nextDueDate: _startDate.isAfter(now)
              ? DateTime(_startDate.year, _startDate.month, _startDate.day)
              : today,
          note: note,
          createdAt: now,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('recurring')
            .doc(recurring.id)
            .set(recurring.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          _isEditing ? 'Failed to update. Please try again.' : 'Failed to save. Please try again.',
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
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final currency =
        ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final currencySymbol =
        NumberFormat.simpleCurrency(name: currency).currencySymbol;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Text('Category', style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            CategorySelector(
              selectedId: _selectedCategoryId,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
              categories: CategoryModel.defaults
                  .where((c) => c.id != 'savings')
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Frequency ─────────────────────────────────────────────
            Text('Frequency', style: AppTextStyles.labelLarge(color: onBg)),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
            Text('Start Date', style: AppTextStyles.labelLarge(color: onBg)),
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
                    Icon(Icons.calendar_today_rounded, size: 18, color: muted),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(_startDate),
                      style: AppTextStyles.bodyMedium(color: onBg),
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
            const SizedBox(height: AppSpacing.sm),

            // ── Pause / Resume toggle (edit only) ─────────────────────
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active',
                          style: AppTextStyles.labelLarge(color: onBg),
                        ),
                        Text(
                          _isActive
                              ? 'Expenses will be tracked automatically'
                              : 'No expenses will be recorded',
                          style: AppTextStyles.labelSmall(color: muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.xs),

            // ── Delete (edit only) ────────────────────────────────────
            if (_isEditing) ...[
              OutlinedButton(
                onPressed: _isSaving ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  'Delete Recurring Expense',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            // ── Save ──────────────────────────────────────────────────
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Save',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
