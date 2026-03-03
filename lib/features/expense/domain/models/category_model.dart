import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isDefault = true,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isDefault;

  /// Default system categories
  static const List<CategoryModel> defaults = [
    CategoryModel(
      id: 'food',
      name: 'Food & Drink',
      emoji: '🍔',
      color: AppColors.catFood,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transport',
      emoji: '🚗',
      color: AppColors.catTransport,
    ),
    CategoryModel(
      id: 'housing',
      name: 'Housing',
      emoji: '🏠',
      color: AppColors.catHousing,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      emoji: '💊',
      color: AppColors.catHealth,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      emoji: '🛍',
      color: AppColors.catShopping,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      emoji: '🎮',
      color: AppColors.catEntertainment,
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      emoji: '📚',
      color: AppColors.catEducation,
    ),
    CategoryModel(
      id: 'work',
      name: 'Work',
      emoji: '💼',
      color: AppColors.catWork,
    ),
    CategoryModel(
      id: 'travel',
      name: 'Travel',
      emoji: '✈️',
      color: AppColors.catTravel,
    ),
    CategoryModel(
      id: 'utilities',
      name: 'Utilities',
      emoji: '🔧',
      color: AppColors.catUtilities,
    ),
    CategoryModel(
      id: 'gifts',
      name: 'Gifts',
      emoji: '🎁',
      color: AppColors.catGifts,
    ),
    CategoryModel(
      id: 'savings',
      name: 'Savings',
      emoji: '💰',
      color: AppColors.catSavings,
    ),
    CategoryModel(
      id: 'other',
      name: 'Other',
      emoji: '📦',
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
