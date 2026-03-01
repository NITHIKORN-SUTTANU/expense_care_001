import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Form section for editing daily/weekly/monthly budget limits.
/// Daily is required; weekly/monthly have toggle switches.
class BudgetLimitForm extends StatefulWidget {
  const BudgetLimitForm({
    super.key,
    required this.dailyLimit,
    this.weeklyLimit,
    this.monthlyLimit,
    required this.showWeekly,
    required this.showMonthly,
    required this.onSave,
  });

  final double dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final bool showWeekly;
  final bool showMonthly;
  final void Function({
    required double daily,
    double? weekly,
    double? monthly,
    required bool showWeekly,
    required bool showMonthly,
  }) onSave;

  @override
  State<BudgetLimitForm> createState() => _BudgetLimitFormState();
}

class _BudgetLimitFormState extends State<BudgetLimitForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dailyCtrl;
  late final TextEditingController _weeklyCtrl;
  late final TextEditingController _monthlyCtrl;
  late bool _weeklyEnabled;
  late bool _monthlyEnabled;
  bool _hasChanges = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dailyCtrl =
        TextEditingController(text: widget.dailyLimit.toStringAsFixed(2));
    _weeklyCtrl = TextEditingController(
        text: widget.weeklyLimit?.toStringAsFixed(2) ?? '');
    _monthlyCtrl = TextEditingController(
        text: widget.monthlyLimit?.toStringAsFixed(2) ?? '');
    _weeklyEnabled = widget.showWeekly;
    _monthlyEnabled = widget.showMonthly;

    _dailyCtrl.addListener(_markChanged);
    _weeklyCtrl.addListener(_markChanged);
    _monthlyCtrl.addListener(_markChanged);
  }

  void _markChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _dailyCtrl.dispose();
    _weeklyCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate async
    widget.onSave(
      daily: double.parse(_dailyCtrl.text),
      weekly: _weeklyEnabled ? double.tryParse(_weeklyCtrl.text) : null,
      monthly: _monthlyEnabled ? double.tryParse(_monthlyCtrl.text) : null,
      showWeekly: _weeklyEnabled,
      showMonthly: _monthlyEnabled,
    );
    setState(() {
      _saving = false;
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget limits saved ✓'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validatePositive(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'This field is required' : null;
    }
    final n = double.tryParse(value);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than 0';
    if (value.replaceAll('.', '').length > 10) return 'Too large';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Daily Limit (required) ─────────────────────────────────────
          _LimitRow(
            label: 'Daily Limit',
            subtitle: 'Required',
            controller: _dailyCtrl,
            enabled: true,
            showToggle: false,
            validator: (v) => _validatePositive(v),
            isDark: isDark,
          ),

          Divider(height: 1, color: dividerColor),

          // ── Weekly Limit ───────────────────────────────────────────────
          _LimitRow(
            label: 'Weekly Limit',
            subtitle: 'Optional — shows on home',
            controller: _weeklyCtrl,
            enabled: _weeklyEnabled,
            showToggle: true,
            toggleValue: _weeklyEnabled,
            onToggle: (val) => setState(() {
              _weeklyEnabled = val;
              _hasChanges = true;
            }),
            validator: _weeklyEnabled ? (v) => _validatePositive(v) : null,
            isDark: isDark,
          ),

          Divider(height: 1, color: dividerColor),

          // ── Monthly Limit ──────────────────────────────────────────────
          _LimitRow(
            label: 'Monthly Limit',
            subtitle: 'Optional — shows on home',
            controller: _monthlyCtrl,
            enabled: _monthlyEnabled,
            showToggle: true,
            toggleValue: _monthlyEnabled,
            onToggle: (val) => setState(() {
              _monthlyEnabled = val;
              _hasChanges = true;
            }),
            validator: _monthlyEnabled ? (v) => _validatePositive(v) : null,
            isDark: isDark,
          ),

          Divider(height: 1, color: dividerColor),

          // ── Save Button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_hasChanges && !_saving) ? _handleSave : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Limits'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.subtitle,
    required this.controller,
    required this.enabled,
    required this.showToggle,
    this.toggleValue,
    this.onToggle,
    this.validator,
    required this.isDark,
  });

  final String label;
  final String subtitle;
  final TextEditingController controller;
  final bool enabled;
  final bool showToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final FormFieldValidator<String>? validator;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showToggle) ...[
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: toggleValue ?? false,
                onChanged: onToggle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelLarge(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.onBackground,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: validator,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? (isDark
                            ? AppColors.darkOnBackground
                            : AppColors.onBackground)
                        : (isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
