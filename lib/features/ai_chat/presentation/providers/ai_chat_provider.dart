import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/models/chat_message.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>(
  (_) => AiChatRepository(),
);

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => AiChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier(this._repository) : super(const AiChatState());

  final AiChatRepository _repository;
  StreamSubscription<String>? _streamSub;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _streamSub != null) return;

    // Add the user message and show typing indicator
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          text: trimmed,
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: true,
      clearError: true,
    );

    final buffer = StringBuffer();
    DateTime? aiTimestamp;
    List<ChatMessage>? pendingMessages;
    Timer? uiTimer;

    void flushUi() {
      uiTimer = null;
      if (!mounted || pendingMessages == null) return;
      state = state.copyWith(messages: pendingMessages);
      pendingMessages = null;
    }

    final completer = Completer<void>();
    _streamSub = _repository
        .sendMessageStream(trimmed)
        .listen(
          (chunk) {
            if (!mounted) return;
            buffer.write(chunk);
            if (aiTimestamp == null) {
              // First chunk — add the AI message (typing indicator disappears)
              aiTimestamp = DateTime.now();
              state = state.copyWith(
                messages: [
                  ...state.messages,
                  ChatMessage(
                    text: buffer.toString(),
                    role: MessageRole.model,
                    timestamp: aiTimestamp!,
                  ),
                ],
              );
            } else {
              // Subsequent chunks — batch UI updates at ~30ms to reduce repaints
              final updated = [...state.messages];
              updated[updated.length - 1] = ChatMessage(
                text: buffer.toString(),
                role: MessageRole.model,
                timestamp: aiTimestamp!,
              );
              pendingMessages = updated;
              uiTimer ??= Timer(const Duration(milliseconds: 30), flushUi);
            }
          },
          onError: (e) {
            uiTimer?.cancel();
            if (mounted) {
              state = state.copyWith(
                isLoading: false,
                error: 'Failed to get a response. Please try again.',
              );
            }
            completer.complete();
          },
          onDone: () {
            uiTimer?.cancel();
            if (mounted) {
              // Flush any buffered update before marking done
              if (pendingMessages != null) {
                state = state.copyWith(
                  messages: pendingMessages,
                  isLoading: false,
                );
              } else {
                state = state.copyWith(isLoading: false);
              }
            }
            completer.complete();
          },
          cancelOnError: true,
        );

    await completer.future;
    _streamSub = null;
  }

  void clearError() => state = state.copyWith(clearError: true);

  void setContext(String context) {
    _repository.setUserContext(context);
  }

  void resetChat(String context) {
    _streamSub?.cancel();
    _streamSub = null;
    _repository.resetSession();
    _repository.setUserContext(context);
    state = const AiChatState(); // isLoading resets to false automatically
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((
  ref,
) {
  return AiChatNotifier(ref.watch(aiChatRepositoryProvider));
});

/// Builds a plain-text financial context string from the user's live data.
String buildUserContext({
  required double dailySpent,
  required double dailyBudget,
  required double weeklySpent,
  required double? weeklyBudget,
  required double monthlySpent,
  required double? monthlyBudget,
  required String currency,
  required String firstName,
  required List recentExpenses,
  required List goals,
}) {
  final buf = StringBuffer();
  buf.writeln('=== USER FINANCIAL DATA ===');
  if (firstName.isNotEmpty) buf.writeln('User: $firstName');
  buf.writeln('Currency: $currency');
  buf.writeln();

  buf.writeln('--- Budgets & Spending ---');
  final dailyPct = dailyBudget > 0
      ? ' (${(dailySpent / dailyBudget * 100).toStringAsFixed(0)}%)'
      : '';
  buf.writeln(
    'Daily:   spent $currency ${dailySpent.toStringAsFixed(2)} / budget $currency ${dailyBudget.toStringAsFixed(2)}$dailyPct',
  );
  if (weeklyBudget != null && weeklyBudget > 0) {
    final pct = (weeklySpent / weeklyBudget * 100).toStringAsFixed(0);
    buf.writeln(
      'Weekly:  spent $currency ${weeklySpent.toStringAsFixed(2)} / budget $currency ${weeklyBudget.toStringAsFixed(2)} ($pct%)',
    );
  }
  if (monthlyBudget != null && monthlyBudget > 0) {
    final pct = (monthlySpent / monthlyBudget * 100).toStringAsFixed(0);
    buf.writeln(
      'Monthly: spent $currency ${monthlySpent.toStringAsFixed(2)} / budget $currency ${monthlyBudget.toStringAsFixed(2)} ($pct%)',
    );
  }
  buf.writeln();

  if (recentExpenses.isNotEmpty) {
    buf.writeln('--- Recent Expenses (latest first) ---');
    for (final e in recentExpenses.take(10)) {
      final note = e.note != null && e.note!.isNotEmpty ? ' (${e.note})' : '';
      buf.writeln(
        '• ${e.categoryId} — $currency ${e.amountInBaseCurrency.toStringAsFixed(2)}$note [${e.date.toLocal().toString().split(' ')[0]}]',
      );
    }
    buf.writeln();
  }

  if (goals.isNotEmpty) {
    buf.writeln('--- Savings Goals ---');
    for (final g in goals) {
      final pct = g.progressPercent;
      buf.writeln(
        '- ${g.name}: saved $currency ${g.savedAmount.toStringAsFixed(2)} / $currency ${g.targetAmount.toStringAsFixed(2)} ($pct%)',
      );
    }
    buf.writeln();
  }

  buf.writeln('=== END OF DATA ===');
  return buf.toString();
}
