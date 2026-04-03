import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/services.dart' show rootBundle;

class AiChatRepository {
  GenerativeModel? _model;
  ChatSession? _session;
  String _userContext = '';
  String? _systemPromptTemplate;

  // Model is built with systemInstruction so the prompt is processed once
  // by the model infrastructure — not re-sent as history on every request.
  GenerativeModel _getModel() {
    return _model ??= FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.system(_buildSystemPrompt()),
    );
  }

  /// Loads the system prompt template from assets if not already loaded
  Future<String> _getSystemPromptTemplate() async {
    if (_systemPromptTemplate == null) {
      _systemPromptTemplate = await rootBundle.loadString(
        'assets/prompts/ai_system_prompt.txt',
      );
    }
    return _systemPromptTemplate!;
  }

  String _buildSystemPrompt() {
    // If template is not loaded yet, use it synchronously
    // This should not happen in normal flow since setUserContext is called first
    final basePrompt = _systemPromptTemplate ?? '';

    return '''
$basePrompt

$_userContext

Today's date is ${DateTime.now().toLocal().toString().split(' ')[0]}.
Always refer to the user's actual data above when answering questions about their spending or budget.
If the data shows no expenses yet, say so honestly.
''';
  }

  ChatSession _getSession() {
    return _session ??= _getModel().startChat();
  }

  Future<void> setUserContext(String context) async {
    // Load the template on first context set
    await _getSystemPromptTemplate();

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
