import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;

  const ChatMessage({required this.role, required this.text});
}

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository);

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(role: MessageRole.user, text: trimmed));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final answer = await _repository.sendMessage(trimmed);
      _messages.add(ChatMessage(role: MessageRole.assistant, text: answer));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}