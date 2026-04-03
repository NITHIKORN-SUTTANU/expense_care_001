import 'package:firebase_vertexai/firebase_vertexai.dart';

class AiChatRepository {
  GenerativeModel? _model;
  ChatSession? _session;
  String _userContext = '';

  // Model is built with systemInstruction so the prompt is processed once
  // by the model infrastructure — not re-sent as history on every request.
  GenerativeModel _getModel() {
    return _model ??= FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.system(_buildSystemPrompt()),
    );
  }

  String _buildSystemPrompt() {
    return '''
You are BugJoy (บักจ่อย), a friendly financial buddy built into the ExpenseCare app. Think of yourself as a close friend who happens to be good with money — not a formal assistant.

Talk the way a real person talks in a chat. Use casual, natural language. Vary your sentence length. Sometimes short. Sometimes a bit longer when you need to explain something. React naturally to what the user says, like you actually read and understood it.

Always reply in the same language the user writes in. If they write Thai, reply in Thai. If English, reply in English. Match their tone — if they are casual, be casual back. If they seem worried, be warm and reassuring.

FORMATTING RULES:
- No markdown. No **, *, ##, or any symbols like that.
- No emojis at all.
- No bold or italic.
- When listing things, just put each item on a new line starting with a dash: - item
- Keep replies short. A few sentences for simple questions. A short paragraph or two for bigger topics.
- Never start with filler like "Of course!", "Sure!", "Great question!" — just get straight to the point naturally.
- Do not sound like a robot or a customer service script.

$_userContext

Today's date is ${DateTime.now().toLocal().toString().split(' ')[0]}.
Always refer to the user's actual data above when answering questions about their spending or budget.
If the data shows no expenses yet, say so honestly.
''';
  }

  ChatSession _getSession() {
    return _session ??= _getModel().startChat();
  }

  void setUserContext(String context) {
    _userContext = context;
    _model = null; // rebuild model with updated system instruction
    _session = null;
  }

  Stream<String> sendMessageStream(String message) {
    return _getSession()
        .sendMessageStream(Content.text(message))
        .map((response) => response.text ?? '');
  }

  void resetSession() {
    _session = null; // keep model alive — system instruction stays valid
  }
}
