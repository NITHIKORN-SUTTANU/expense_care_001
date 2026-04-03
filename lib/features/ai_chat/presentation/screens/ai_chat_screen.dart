import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../features/expense/data/expense_repository.dart';
import '../../../../features/goals/presentation/screens/goals_screen.dart';
import '../../../../shared/providers/user_preferences_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _injectContext());
  }

  void _injectContext() {
    final user = ref.read(userPreferencesNotifierProvider);
    final dailySpent = ref.read(dailyTotalProvider).valueOrNull ?? 0.0;
    final weeklySpent = ref.read(weeklyTotalProvider).valueOrNull ?? 0.0;
    final monthlySpent = ref.read(monthlyTotalProvider).valueOrNull ?? 0.0;
    final recentExpenses = ref.read(recentExpensesProvider).valueOrNull ?? [];
    final goals = ref.read(goalsProvider).valueOrNull ?? [];

    final context = buildUserContext(
      dailySpent: dailySpent,
      dailyBudget: user?.dailyLimit ?? 0.0,
      weeklySpent: weeklySpent,
      weeklyBudget: user?.weeklyLimit,
      monthlySpent: monthlySpent,
      monthlyBudget: user?.monthlyLimit,
      currency: user?.preferredCurrency ?? 'USD',
      firstName: user?.firstName ?? '',
      recentExpenses: recentExpenses,
      goals: goals,
    );

    ref.read(aiChatProvider.notifier).setContext(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final state = ref.watch(aiChatProvider);

    ref.listen(aiChatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: isDark ? AppColors.darkError : AppColors.error,
          ),
        );
        ref.read(aiChatProvider.notifier).clearError();
      }
    });

    // Re-inject context once async data providers finish loading,
    // but only before the conversation starts so we don't reset mid-chat.
    void reInjectIfFresh(AsyncValue<dynamic> next) {
      if (next.hasValue && state.messages.isEmpty) _injectContext();
    }

    ref.listen(dailyTotalProvider, (_, next) => reInjectIfFresh(next));
    ref.listen(weeklyTotalProvider, (_, next) => reInjectIfFresh(next));
    ref.listen(monthlyTotalProvider, (_, next) => reInjectIfFresh(next));
    ref.listen(recentExpensesProvider, (_, next) => reInjectIfFresh(next));
    ref.listen(goalsProvider, (_, next) => reInjectIfFresh(next));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primary.withValues(alpha: 0.15),
              child: Icon(Icons.smart_toy_rounded, size: 18, color: primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BugJoy (บักจ่อย)', style: AppTextStyles.titleMedium()),
                Text(
                  'Powered by Gemini',
                  style: AppTextStyles.labelSmall(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              onPressed: () {
                _injectContext();
                ref
                    .read(aiChatProvider.notifier)
                    .resetChat(
                      buildUserContext(
                        dailySpent:
                            ref.read(dailyTotalProvider).valueOrNull ?? 0.0,
                        dailyBudget:
                            ref
                                .read(userPreferencesNotifierProvider)
                                ?.dailyLimit ??
                            0.0,
                        weeklySpent:
                            ref.read(weeklyTotalProvider).valueOrNull ?? 0.0,
                        weeklyBudget: ref
                            .read(userPreferencesNotifierProvider)
                            ?.weeklyLimit,
                        monthlySpent:
                            ref.read(monthlyTotalProvider).valueOrNull ?? 0.0,
                        monthlyBudget: ref
                            .read(userPreferencesNotifierProvider)
                            ?.monthlyLimit,
                        currency:
                            ref
                                .read(userPreferencesNotifierProvider)
                                ?.preferredCurrency ??
                            'USD',
                        firstName:
                            ref
                                .read(userPreferencesNotifierProvider)
                                ?.firstName ??
                            '',
                        recentExpenses:
                            ref.read(recentExpensesProvider).valueOrNull ?? [],
                        goals: ref.read(goalsProvider).valueOrNull ?? [],
                      ),
                    );
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _WelcomeView(isDark: isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    // Show typing indicator only while waiting for the first
                    // chunk (isLoading=true and last message is still from user)
                    itemCount:
                        state.messages.length +
                        (state.isLoading &&
                                (state.messages.isEmpty ||
                                    state.messages.last.isUser)
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return _TypingIndicator(isDark: isDark);
                      }
                      return ChatBubble(message: state.messages[index]);
                    },
                  ),
          ),
          ChatInputBar(
            onSend: ref.read(aiChatProvider.notifier).sendMessage,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Welcome / empty state ─────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, size: 48, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Hi! I\'m BugJoy (บักจ่อย)',
              style: AppTextStyles.titleLarge(
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your expenses, budgets, financial goals, or get personalised money-saving tips.',
              style: AppTextStyles.bodyMedium(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(label: 'How can I cut back on spending?'),
                _SuggestionChip(label: 'Give me budgeting tips'),
                _SuggestionChip(label: 'How do I save more each month?'),
                _SuggestionChip(label: 'Explain the 50/30/20 rule'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends ConsumerWidget {
  const _SuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return InkWell(
      onTap: () => ref.read(aiChatProvider.notifier).sendMessage(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: AppTextStyles.labelMedium(color: primary)),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.isDark});

  final bool isDark;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Icon(Icons.smart_toy_rounded, size: 16, color: primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_controller.value + i * 0.25) % 1.0;
                    final scale = phase < 0.5 ? 1.0 + phase : 2.0 - phase;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                        scale: scale.clamp(1.0, 1.5),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
