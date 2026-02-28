import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Full-width "Add Expense" button as a prominent inline card.
/// On mobile: opens AddExpenseScreen as modal bottom sheet.
/// On web (>= 840dp): navigates to full screen.
class QuickAddFab extends StatelessWidget {
  const QuickAddFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final primaryVariant =
        isDark ? AppColors.darkPrimaryVariant : AppColors.primaryVariant;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Add Expense'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.1),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.pressed) ? primaryVariant : primary,
          ),
        ),
      ),
    );
  }
}
