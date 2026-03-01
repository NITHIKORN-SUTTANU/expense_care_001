import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../../data/expense_repository.dart';
import '../../domain/models/expense_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../widgets/category_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  /// When provided, the screen operates in edit mode.
  final ExpenseModel? expense;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _noteCtrl.text = e.note ?? '';
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _amountCtrl.text.isNotEmpty && _selectedCategoryId != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _selectedDate.hour,
        time?.minute ?? _selectedDate.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      showErrorSnackBar(context, 'Please select a category.');
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final currency =
        ref.read(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final repo = ref.read(expenseRepositoryProvider);

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        final updated = widget.expense!.copyWith(
          amount: amount,
          amountInBaseCurrency: amount,
          categoryId: _selectedCategoryId!,
          note: note,
          date: _selectedDate,
        );
        await repo.update(updated);
        if (mounted) {
          showSuccessSnackBar(context, 'Expense updated!');
          Navigator.of(context).pop();
        }
      } else {
        final expense = ExpenseModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: uid,
          amount: amount,
          currency: currency,
          amountInBaseCurrency: amount,
          categoryId: _selectedCategoryId!,
          note: note,
          date: _selectedDate,
          syncedToFirestore: true,
          createdAt: DateTime.now(),
        );
        await repo.add(expense);
        if (mounted) {
          showSuccessSnackBar(context, 'Expense added!');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          _isEditing ? 'Failed to update expense.' : 'Failed to save expense.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .delete(uid, widget.expense!.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Expense deleted.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to delete expense.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final currency = ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final currencySymbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount ──────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Amount',
              style: AppTextStyles.labelLarge(
                color: isDark ? AppColors.darkOnBackground : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppTextField(
              controller: _amountCtrl,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              prefixText: '$currencySymbol ',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: Validators.amount,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Category ────────────────────────────────────────────────
            Text(
              'Category',
              style: AppTextStyles.labelLarge(
                color: isDark ? AppColors.darkOnBackground : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            CategorySelector(
              selectedId: _selectedCategoryId,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
            ),
            if (_selectedCategoryId == null && _formKey.currentState != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Please select a category',
                  style: AppTextStyles.labelSmall(color: AppColors.error),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // ── Date & Time ──────────────────────────────────────────────
            Text(
              'Date & Time',
              style: AppTextStyles.labelLarge(
                color: isDark ? AppColors.darkOnBackground : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            GestureDetector(
              onTap: _pickDate,
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
                      DateFormat('EEE, MMM d · h:mm a').format(_selectedDate),
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

            const SizedBox(height: AppSpacing.md),

            // ── Note ─────────────────────────────────────────────────────
            Text(
              'Note (optional)',
              style: AppTextStyles.labelLarge(
                color: isDark ? AppColors.darkOnBackground : AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppTextField(
              controller: _noteCtrl,
              hint: 'e.g. Morning coffee',
              maxLength: 200,
              textInputAction: TextInputAction.done,
              validator: Validators.note,
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Submit ───────────────────────────────────────────────────
            if (_isEditing) ...[
              OutlinedButton(
                onPressed: _isLoading ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text('Delete Expense'),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Add Expense',
              onPressed: _canSubmit && !_isLoading ? _submit : null,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
