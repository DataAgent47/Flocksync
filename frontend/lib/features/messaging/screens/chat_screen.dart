import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/flock_theme.dart';
import '../../../models/chat_message.dart';
import '../../../models/building_user.dart';
import '../controllers/messaging_controller.dart';

class ChatScreen extends StatefulWidget {
  final BuildingUser otherUser;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _messageController;
  late final MessagingController _messagingController;
  late final ScrollController _scrollController;
  late final Stream<List<ChatMessage>> _messagesStream;
  late final Stream<bool> _typingStream;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(_onTextChanged);
    _scrollController = ScrollController();
    _messagingController = MessagingController(
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUser.userId,
      otherUserName: widget.otherUser.fullName,
    );
    _messagesStream = _messagingController.messagesStream();
    _typingStream = _messagingController.typingStream();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messagingController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onMessageChanged(String text) {
    _messagingController.setTypingStatus(text.isNotEmpty);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _messagingController.setTypingStatus(false);

    await _messagingController.sendMessage(
      text: text,
    );

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return ChangeNotifierProvider.value(
      value: _messagingController,
      child: Scaffold(
        backgroundColor: FlockColors.background,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: FlockColors.background,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back,
                            color: FlockColors.darkGreen,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.otherUser.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FlockColors.darkGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Message list
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: FlockColors.darkGreen,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final errorText = snapshot.error?.toString() ?? 'Unknown error';
                    return Center(
                      child: Text(
                        'Error loading messages: $errorText',
                        style: const TextStyle(
                          color: FlockColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: const TextStyle(
                          color: FlockColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  // Auto-scroll to bottom on new messages
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser =
                          message.senderId == widget.currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? FlockColors.darkGreen
                                    : FlockColors.cardBackground,
                                border: isCurrentUser
                                    ? null
                                    : Border.all(
                                        color: FlockColors.darkGreen,
                                        width: 1.25,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? FlockColors.cream
                                          : FlockColors.darkGreen,
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? FlockColors.cream.withValues(alpha: 0.7)
                                          : FlockColors.midGreen,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Typing indicator
            StreamBuilder<bool>(
              stream: _typingStream,
              builder: (context, snapshot) {
                final isTyping = snapshot.data ?? false;
                if (!isTyping) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        '${widget.otherUser.firstName} is typing...',
                        style: const TextStyle(
                          color: FlockColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: FlockColors.cream,
                border: Border(
                  top: BorderSide(
                    color: FlockColors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onMessageChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: FlockColors.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: FlockColors.divider,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: FlockColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: FlockColors.darkGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: null,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _messageController.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isEmpty
                            ? FlockColors.divider
                            : FlockColors.darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: FlockColors.cream,
                        size: 18,
                      ),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
