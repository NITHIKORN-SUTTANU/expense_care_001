import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.isLoading,
  });

  final void Function(String) onSend;
  final bool isLoading;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isLoading,
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.send,
                  maxLines: 4,
                  minLines: 1,
                  style: AppTextStyles.bodyMedium(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about your finances…',
                    hintStyle: AppTextStyles.bodyMedium(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: widget.isLoading
                    ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primary,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _submit,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
