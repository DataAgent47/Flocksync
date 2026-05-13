import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../services/messaging_service.dart';

class MessagingController extends ChangeNotifier {
  final MessagingService _service = MessagingService();
  
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  MessagingController({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  Timer? _typingDebounceTimer;
  bool _isTyping = false;

  Stream<List<ChatMessage>> messagesStream() {
    return _service.messagesStream(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  Stream<bool> typingStream() {
    return _service.typingStream(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  /// Send a message
  Future<void> sendMessage({required String text}) async {
    await _service.sendMessage(
      senderId: currentUserId,
      recipientId: otherUserId,
      text: text,
    );
  }

  /// Set typing status with debouncing (250ms)
  void setTypingStatus(bool isTyping) {
    if (isTyping == _isTyping && isTyping) {
      _startDebounceTimer();
      return;
    }

    _isTyping = isTyping;
    _typingDebounceTimer?.cancel();

    if (isTyping) {
      _startDebounceTimer();
    } else {
      _service.setTypingStatus(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        isTyping: false,
      );
    }
  }

  void _startDebounceTimer() {
    _typingDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      _service.setTypingStatus(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        isTyping: true,
      );
    });
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    // Clear typing status on dispose
    _service.setTypingStatus(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      isTyping: false,
    );
    super.dispose();
  }
}
