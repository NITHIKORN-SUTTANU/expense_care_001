import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/receipt_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../../data/expense_repository.dart';
import '../../domain/models/expense_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../../domain/models/category_model.dart';
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
  File? _pickedReceipt;
  bool _receiptRemoved = false;

  bool get _isEditing => widget.expense != null;
  bool get _isSavingsEdit =>
      _isEditing && widget.expense!.categoryId == 'savings';

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _noteCtrl.text = e.note ?? '';
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date.toLocal();
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
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      withTime: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final file = await ReceiptService.instance.pick(source);
      if (file == null || !mounted) return;
      setState(() {
        _pickedReceipt = file;
        _receiptRemoved = false;
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Could not access photos: $e');
    }
  }

  Widget _buildReceiptSection(bool isDark, Color muted, Color divColor) {
    final existingUrl =
        _receiptRemoved ? null : widget.expense?.receiptImageUrl;
    final hasReceipt = _pickedReceipt != null || existingUrl != null;
    if (hasReceipt) {
      return _ReceiptThumbnail(
        file: _pickedReceipt,
        url: existingUrl,
        onRemove: () => setState(() {
          _pickedReceipt = null;
          _receiptRemoved = true;
        }),
      );
    }
    return _ReceiptPicker(
      divColor: divColor,
      muted: muted,
      onPick: _pickReceipt,
    );
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
    // Determine ID upfront — needed for the Storage upload path.
    final expenseId = _isEditing
        ? widget.expense!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    setState(() => _isLoading = true);
    try {
      // ── Receipt handling ────────────────────────────────────────────────────
      String? receiptUrl;
      if (_pickedReceipt != null) {
        receiptUrl = await ReceiptService.instance
            .upload(uid, expenseId, _pickedReceipt!);
      } else if (_receiptRemoved) {
        await ReceiptService.instance.delete(uid, expenseId);
        // receiptUrl stays null
      } else {
        receiptUrl = _isEditing ? widget.expense!.receiptImageUrl : null;
      }

      if (_isEditing) {
        final old = widget.expense!;
        final updated = old.copyWith(
          amount: amount,
          currency: currency,
          amountInBaseCurrency: amount,
          categoryId: _selectedCategoryId!,
          note: note,
          receiptImageUrl: receiptUrl,
          clearReceiptUrl: _receiptRemoved,
          date: _selectedDate,
        );
        await repo.update(updated);

        // Sync linked goal when amount or category changes.
        if (old.goalId != null) {
          final goalRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc(old.goalId);
          final snap = await goalRef.get();
          if (snap.exists) {
            final data = snap.data()!;
            final currentSaved =
                (data['savedAmount'] as num?)?.toDouble() ?? 0.0;
            final targetAmount = (data['targetAmount'] as num).toDouble();
            final double newSaved;
            if (_selectedCategoryId == 'savings') {
              newSaved = (currentSaved + (amount - old.amountInBaseCurrency))
                  .clamp(0.0, double.infinity);
            } else {
              newSaved = (currentSaved - old.amountInBaseCurrency)
                  .clamp(0.0, double.infinity);
            }
            await goalRef.update({
              'savedAmount': newSaved,
              'isCompleted': newSaved >= targetAmount,
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        }

        if (mounted) {
          showSuccessSnackBar(context, 'Expense updated!');
          Navigator.of(context).pop();
        }
      } else {
        final expense = ExpenseModel(
          id: expenseId,
          userId: uid,
          amount: amount,
          currency: currency,
          amountInBaseCurrency: amount,
          categoryId: _selectedCategoryId!,
          note: note,
          receiptImageUrl: receiptUrl,
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
      final expense = widget.expense!;
      await ref.read(expenseRepositoryProvider).delete(uid, expense.id);

      // Reverse the saved amount on the linked goal.
      if (expense.categoryId == 'savings' && expense.goalId != null) {
        final goalRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(expense.goalId);
        final snap = await goalRef.get();
        if (snap.exists) {
          final data = snap.data()!;
          final currentSaved =
              (data['savedAmount'] as num?)?.toDouble() ?? 0.0;
          final targetAmount = (data['targetAmount'] as num).toDouble();
          final newSaved =
              (currentSaved - expense.amountInBaseCurrency)
                  .clamp(0.0, double.infinity);
          await goalRef.update({
            'savedAmount': newSaved,
            'isCompleted': newSaved >= targetAmount,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

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
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;

    // Use the expense's own currency for savings edit (locked), otherwise
    // always use the user's current preferred currency.
    final currency = _isSavingsEdit
        ? widget.expense!.currency
        : (ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ??
            'USD');
    final currencySymbol =
        NumberFormat.simpleCurrency(name: currency).currencySymbol;

    final padding = EdgeInsets.only(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: AppSpacing.xs,
      bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
    );

    // ── Savings edit: simplified read-only view ──────────────────────────────
    if (_isSavingsEdit) {
      final expense = widget.expense!;
      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Amount (editable)
              Text('Amount', style: AppTextStyles.labelLarge(color: onBg)),
              const SizedBox(height: AppSpacing.xxs),
              AppTextField(
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                prefixText: '$currencySymbol ',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: Validators.amount,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.md),

              // Date (read-only)
              Text('Date & Time',
                  style: AppTextStyles.labelLarge(color: muted)),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.background,
                  border: Border.all(color: divColor),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, MMM d · h:mm a')
                            .format(expense.date.toLocal()),
                        style: AppTextStyles.bodyMedium(color: muted),
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded, size: 14, color: muted),
                  ],
                ),
              ),

              // Linked goal (read-only)
              if (expense.goalId != null && expense.note != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Linked Goal',
                    style: AppTextStyles.labelLarge(color: muted)),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    border: Border.all(color: divColor),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          expense.note!,
                          style: AppTextStyles.bodyMedium(color: muted),
                        ),
                      ),
                      Icon(Icons.lock_outline_rounded,
                          size: 14, color: muted),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

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
              AppButton(
                label: 'Save Changes',
                onPressed: _canSubmit && !_isLoading ? _submit : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      );
    }

    // ── Regular add / edit form ──────────────────────────────────────────────
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount ────────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Text('Amount', style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            AppTextField(
              controller: _amountCtrl,
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              prefixText: '$currencySymbol ',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: Validators.amount,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Category ──────────────────────────────────────────────────
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

            // ── Date & Time ───────────────────────────────────────────────
            Text('Date & Time', style: AppTextStyles.labelLarge(color: onBg)),
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
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: muted),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEE, MMM d · h:mm a')
                          .format(_selectedDate),
                      style: AppTextStyles.bodyMedium(color: onBg),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Note ──────────────────────────────────────────────────────
            Text('Note (optional)',
                style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            AppTextField(
              controller: _noteCtrl,
              hint: 'e.g. Morning coffee',
              maxLength: 200,
              textInputAction: TextInputAction.done,
              validator: Validators.note,
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Receipt ───────────────────────────────────────────────────
            Text('Receipt (optional)',
                style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            _buildReceiptSection(isDark, muted, divColor),

            const SizedBox(height: AppSpacing.lg),

            // ── Submit ────────────────────────────────────────────────────
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

// ── Receipt thumbnail (shows picked file or existing network image) ───────────

class _ReceiptThumbnail extends StatelessWidget {
  const _ReceiptThumbnail({
    required this.file,
    required this.url,
    required this.onRemove,
  });

  final File? file;
  final String? url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageWidget = file != null
        ? Image.file(file!, fit: BoxFit.cover, width: double.infinity)
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            width: double.infinity,
          );

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: 140, child: imageWidget),
          ),
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          // Tap-to-view hint
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tap to view',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context) {
    final imageProvider = file != null
        ? FileImage(file!) as ImageProvider
        : CachedNetworkImageProvider(url!);

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image(image: imageProvider)),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt picker (empty state — tap to choose camera or gallery) ────────────

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
    required this.divColor,
    required this.muted,
    required this.onPick,
  });

  final Color divColor;
  final Color muted;
  final Future<void> Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSourceSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border.all(color: divColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: muted, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add receipt',
              style: TextStyle(
                color: muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      // Must match the outer sheet (showAppBottomSheet uses useRootNavigator:true)
      // so this sheet layers above it correctly.
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onPick(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
