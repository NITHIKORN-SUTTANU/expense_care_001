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
import '../../../expense/data/expense_repository.dart';
import '../../../expense/domain/models/expense_model.dart';
import '../../domain/models/goal_model.dart';

// ── Firestore provider ────────────────────────────────────────────────────────

final goalsProvider = StreamProvider<List<GoalModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('goals')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GoalModel.fromMap(d.data(), d.id)).toList());
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _openAddGoal(BuildContext context) {
    showAppBottomSheet(
      context: context,
      title: 'New Goal',
      child: const _GoalFormSheet(),
    );
  }

  void _openEditGoal(BuildContext context, GoalModel goal) {
    showAppBottomSheet(
      context: context,
      title: 'Edit Goal',
      child: _GoalFormSheet(goal: goal),
    );
  }

  void _openAddMoney(BuildContext context, GoalModel goal) {
    showAppBottomSheet(
      context: context,
      title: 'Add to "${goal.name}"',
      child: _AddMoneySheet(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final currency =
        ref.watch(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            titleSpacing: 20,
            title: Text(
              'Goals',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _openAddGoal(context),
                tooltip: 'Add Goal',
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

          if (goals.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                emoji: '🎯',
                title: 'No goals yet',
                subtitle: 'Set your first goal and start saving!',
                actionLabel: 'Add Goal',
                onAction: () => _openAddGoal(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  20, AppSpacing.sm, 20, AppSpacing.sm + 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final goal = goals[i];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < goals.length - 1 ? AppSpacing.sm : 0),
                      child: _GoalCard(
                        goal: goal,
                        currency: currency,
                        isDark: isDark,
                        onEdit: () => _openEditGoal(context, goal),
                        onAddMoney: () => _openAddMoney(context, goal),
                      ),
                    );
                  },
                  childCount: goals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.isDark,
    required this.onEdit,
    required this.onAddMoney,
  });

  final GoalModel goal;
  final String currency;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onAddMoney;

  String _fmt(double v) =>
      NumberFormat.simpleCurrency(name: currency, decimalDigits: 2).format(v);

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.secondary;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final progressColor = goal.isCompleted ? AppColors.success : primary;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular progress ring with emoji ──────────────────
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: goal.progress,
                      strokeWidth: 4.5,
                      backgroundColor: borderColor,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    Text(goal.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Details ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTextStyles.labelLarge(color: onBg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(goal.savedAmount)} of ${_fmt(goal.targetAmount)}',
                      style: AppTextStyles.labelSmall(color: muted),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        backgroundColor: borderColor,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 5,
                      ),
                    ),
                    if (goal.targetDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${DateFormat('MMM d, y').format(goal.targetDate!)}',
                        style: AppTextStyles.labelSmall(color: muted),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // ── Right: actions column ──────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (goal.isCompleted)
                    const Text('🎉', style: TextStyle(fontSize: 22))
                  else ...[
                    Text(
                      '${goal.progressPercent}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onAddMoney,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Goal Form Sheet (Add & Edit) ──────────────────────────────────────────────

class _GoalFormSheet extends ConsumerStatefulWidget {
  const _GoalFormSheet({this.goal});
  final GoalModel? goal;

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late String _emoji;
  DateTime? _targetDate;
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  static const _emojis = [
    '🎯', '🏠', '✈️', '💻', '🚗', '📱',
    '🎓', '💎', '🛡️', '🎮', '📷', '🌴',
    '👟', '🎵', '🏋️', '🐾', '🛒', '💍',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _targetCtrl = TextEditingController(
      text: g != null
          ? g.targetAmount.toStringAsFixed(
              g.targetAmount == g.targetAmount.truncate() ? 0 : 2)
          : '',
    );
    _emoji = g?.emoji ?? '🎯';
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    bool deleteExpenses = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove "${widget.goal!.name}" from your goals?'),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: deleteExpenses,
                onChanged: (v) =>
                    setDialogState(() => deleteExpenses = v ?? false),
                title: const Text(
                  'Also delete linked savings expenses',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
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
      ),
    );
    if (confirmed != true || !mounted) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    try {
      if (deleteExpenses) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .where('goalId', isEqualTo: widget.goal!.id)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(widget.goal!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'Failed to delete goal.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final currency =
        ref.read(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';
    final targetAmount =
        double.parse(_targetCtrl.text.replaceAll(',', ''));

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      if (_isEditing) {
        final savedAmount = widget.goal!.savedAmount;
        final newName = _nameCtrl.text.trim();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(widget.goal!.id)
            .update({
          'name': newName,
          'emoji': _emoji,
          'targetAmount': targetAmount,
          'isCompleted': savedAmount >= targetAmount,
          'targetDate': _targetDate?.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        // If the name changed, update the note on all linked savings expenses.
        if (newName != widget.goal!.name) {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .where('goalId', isEqualTo: widget.goal!.id)
              .get();
          if (snap.docs.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in snap.docs) {
              batch.update(doc.reference, {'note': newName});
            }
            await batch.commit();
          }
        }
      } else {
        final goal = GoalModel(
          id: now.millisecondsSinceEpoch.toString(),
          userId: uid,
          name: _nameCtrl.text.trim(),
          emoji: _emoji,
          targetAmount: targetAmount,
          savedAmount: 0,
          currency: currency,
          targetDate: _targetDate,
          createdAt: now,
          updatedAt: now,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(goal.id)
            .set(goal.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
            context, _isEditing ? 'Failed to update goal.' : 'Failed to save goal.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final onBg = isDark ? AppColors.darkOnBackground : AppColors.onBackground;
    final muted = isDark ? AppColors.darkMuted : AppColors.muted;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Icon picker ───────────────────────────────────────────
            Text('Icon', style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? primary : divColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child:
                          Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Goal name ─────────────────────────────────────────────
            AppTextField(
              controller: _nameCtrl,
              label: 'Goal Name',
              validator: Validators.goalName,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Target amount ─────────────────────────────────────────
            AppTextField(
              controller: _targetCtrl,
              label: 'Target Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixText: '$currencySymbol ',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              ],
              validator: (v) => Validators.requiredPositiveNumber(
                  v, label: 'Target amount'),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Target date (optional) ────────────────────────────────
            Text('Target Date (optional)',
                style: AppTextStyles.labelLarge(color: onBg)),
            const SizedBox(height: AppSpacing.xxs),
            GestureDetector(
              onTap: () async {
                final picked = await showAppDatePicker(
                  context: context,
                  initialDate: _targetDate ??
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(() => _targetDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
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
                        _targetDate != null
                            ? DateFormat('MMM d, y').format(_targetDate!)
                            : 'No target date',
                        style: AppTextStyles.bodyMedium(
                          color: _targetDate != null ? onBg : muted,
                        ),
                      ),
                    ),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: muted),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

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
                child: const Text('Delete Goal'),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            AppButton(
              label: _isEditing ? 'Save Changes' : 'Save Goal',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Money Sheet ───────────────────────────────────────────────────────────

class _AddMoneySheet extends ConsumerStatefulWidget {
  const _AddMoneySheet({required this.goal});
  final GoalModel goal;

  @override
  ConsumerState<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<_AddMoneySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final currency =
        ref.read(userPreferencesNotifierProvider)?.preferredCurrency ?? 'USD';

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();

      // 1. Record as a Savings expense so budget is updated
      final expense = ExpenseModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: uid,
        amount: amount,
        currency: currency,
        amountInBaseCurrency: amount,
        categoryId: 'savings',
        note: widget.goal.name,
        date: now,
        goalId: widget.goal.id,
        syncedToFirestore: true,
        createdAt: now,
      );
      await ref.read(expenseRepositoryProvider).add(expense);

      // 2. Update goal saved amount
      final newSaved = widget.goal.savedAmount + amount;
      final isCompleted = newSaved >= widget.goal.targetAmount;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(widget.goal.id)
          .update({
        'savedAmount': newSaved,
        'isCompleted': isCompleted,
        'updatedAt': now.toIso8601String(),
      });

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, 'Failed to add funds.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount ────────────────────────────────────────────────
            AppTextField(
              controller: _amountCtrl,
              label: 'Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixText: '$currencySymbol ',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              ],
              validator: (v) =>
                  Validators.requiredPositiveNumber(v, label: 'Amount'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirm(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Info box ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💰',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recorded as a Savings expense and deducted from today\'s budget.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AppButton(
              label: 'Confirm',
              onPressed: _isSaving ? null : _confirm,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
