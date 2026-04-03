import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

class AiChatCard extends StatelessWidget {
  const AiChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final primaryVariant = isDark
        ? AppColors.darkPrimaryVariant
        : AppColors.primaryVariant;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.aiChat),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primaryVariant],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative background circles
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 28,
              bottom: -24,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Cartoon robot avatar
                  const _RobotAvatar(),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat with BugJoy',
                          style: AppTextStyles.titleMedium(color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ask about your expenses,\nbudgets & goals',
                          style: AppTextStyles.bodyMedium(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cartoon robot avatar ──────────────────────────────────────────────────────

class _RobotAvatar extends StatelessWidget {
  const _RobotAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 78,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Antenna stem
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Antenna tip dot
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Robot head
          Positioned(
            bottom: 0,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
