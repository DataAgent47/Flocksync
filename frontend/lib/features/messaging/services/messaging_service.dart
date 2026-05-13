import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chat_message.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateConversationId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Stream all messages in a conversation
  Stream<List<ChatMessage>> messagesStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    final conversationId = _generateConversationId(currentUserId, otherUserId);
    
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream typing status of the other user
  Stream<bool> typingStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    final conversationId = _generateConversationId(currentUserId, otherUserId);
    final docId = '${conversationId}_$otherUserId';

    // Calculate the time of expiring typing status
    final controller = StreamController<bool>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? expiryTimer;

    subscription = _firestore
        .collection('typing_status')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
            expiryTimer?.cancel();

            final data = snapshot.data();
            final isTyping = snapshot.exists && data != null && (data['isTyping'] as bool? ?? false);
            final timestamp = snapshot.exists && data != null ? (data['timestamp'] as Timestamp?)?.toDate() : null;
            if (!isTyping || timestamp == null) {
              controller.add(false);
              return;
            }

            // Auto clear if no update for 5 seconds
            final remaining = timestamp.add(const Duration(seconds: 5)).difference(DateTime.now());
            if (remaining <= Duration.zero) {
              controller.add(false);
              return;
            }

            controller.add(true);
            expiryTimer = Timer(remaining, () {
              if (!controller.isClosed) {
                controller.add(false);
              }
            });
          },
          onError: controller.addError,
        );

    controller.onCancel = () async {
      expiryTimer?.cancel();
      await subscription?.cancel();
    };

    return controller.stream.distinct();
  }

  /// Send a message to another user
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final conversationId = _generateConversationId(senderId, recipientId);
    final timestamp = DateTime.now();

    await _firestore.collection('messages').add({
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text.trim(),
      'timestamp': timestamp,
      'conversationId': conversationId,
    });

    // Clear typing status after sending
    await _setTypingStatus(
      currentUserId: senderId,
      otherUserId: recipientId,
      isTyping: false,
    );
  }

  /// Update typing status for current user
  Future<void> setTypingStatus({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    await _setTypingStatus(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      isTyping: isTyping,
    );
  }

  Future<void> _setTypingStatus({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    final conversationId = _generateConversationId(currentUserId, otherUserId);
    final docId = '${conversationId}_$currentUserId';

    await _firestore.collection('typing_status').doc(docId).set(
      {
        'ownerId': currentUserId,
        'otherUserId': otherUserId,
        'conversationId': conversationId,
        'isTyping': isTyping,
        'timestamp': DateTime.now(),
      },
      SetOptions(merge: true),
    );
  }
}
