import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/category_model.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.categories = CategoryModel.defaults,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.circular(AppRadius.chip + 4),
                border: Border.all(
                  color: selected
                      ? primary
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 3),
                  Text(
                    cat.name.split(' ').first,
                    style: AppTextStyles.labelSmall(
                      color: selected
                          ? primary
                          : (isDark
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
