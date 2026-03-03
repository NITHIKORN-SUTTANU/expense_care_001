import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = true,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  /// Default system categories
  static const List<CategoryModel> defaults = [
    CategoryModel(
      id: 'food',
      name: 'Food & Drink',
      icon: Icons.restaurant_rounded,
      color: AppColors.catFood,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: AppColors.catTransport,
    ),
    CategoryModel(
      id: 'housing',
      name: 'Housing',
      icon: Icons.home_rounded,
      color: AppColors.catHousing,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      icon: Icons.medical_services_rounded,
      color: AppColors.catHealth,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.catShopping,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.sports_esports_rounded,
      color: AppColors.catEntertainment,
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      icon: Icons.school_rounded,
      color: AppColors.catEducation,
    ),
    CategoryModel(
      id: 'work',
      name: 'Work',
      icon: Icons.work_rounded,
      color: AppColors.catWork,
    ),
    CategoryModel(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight_rounded,
      color: AppColors.catTravel,
    ),
    CategoryModel(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.build_rounded,
      color: AppColors.catUtilities,
    ),
    CategoryModel(
      id: 'gifts',
      name: 'Gifts',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.catGifts,
    ),
    CategoryModel(
      id: 'savings',
      name: 'Savings',
      icon: Icons.savings_rounded,
      color: AppColors.catSavings,
    ),
    CategoryModel(
      id: 'other',
      name: 'Other',
      icon: Icons.category_rounded,
      color: AppColors.catOther,
    ),
  ];

  static CategoryModel? findById(String id) {
    try {
      return defaults.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
