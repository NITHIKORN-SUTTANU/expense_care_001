import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Segmented control for selecting Light / Dark / System theme.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;

    const modes = [
      (label: 'Light', mode: ThemeMode.light, icon: Icons.light_mode_rounded),
      (label: 'Dark', mode: ThemeMode.dark, icon: Icons.dark_mode_rounded),
      (label: 'System', mode: ThemeMode.system, icon: Icons.contrast_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((item) {
          final isSelected = selectedMode == item.mode;
          return GestureDetector(
            onTap: () => onChanged(item.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 14,
                    color: isSelected ? Colors.white : mutedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
