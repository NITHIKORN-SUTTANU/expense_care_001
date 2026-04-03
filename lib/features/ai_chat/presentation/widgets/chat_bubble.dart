import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 56 : 0,
        right: isUser ? 0 : 56,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: primary.withValues(alpha: 0.15),
              child: Icon(Icons.smart_toy_rounded, size: 16, color: primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? primary
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMedium(
                      color: isUser
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkOnSurface
                                : AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: AppTextStyles.labelSmall(
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.65)
                          : (isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
