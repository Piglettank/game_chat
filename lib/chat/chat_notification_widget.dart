import 'dart:async';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'message.dart';
import '../challenges/challenge.dart';
import '../services/user_storage.dart';
import '../core/navigation_helper.dart';

/// A notification model to display in the popup
class ChatNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final String? challengeId;

  ChatNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.challengeId,
  });
}

enum NotificationType {
  message,
  whisper,
  challenge,
}

/// Widget that listens for new chats and challenges and shows notifications
class ChatNotificationWidget extends StatefulWidget {
  final String chatId;
  final Widget child;

  const ChatNotificationWidget({
    super.key,
    required this.chatId,
    required this.child,
  });

  @override
  State<ChatNotificationWidget> createState() => _ChatNotificationWidgetState();
}

class _ChatNotificationWidgetState extends State<ChatNotificationWidget>
    with SingleTickerProviderStateMixin {
  late ChatService _chatService;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<Challenge>>? _challengesSubscription;

  final List<ChatNotification> _notifications = [];
  DateTime? _lastMessageTimestamp;
  Set<String> _lastChallengeIds = {};
  bool _isMessagesInitialized = false;
  bool _isChallengesInitialized = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String get _userId => UserStorage.hasUserData() ? UserStorage.getUserId() : '';

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(chatId: widget.chatId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _startListening();
  }

  void _startListening() {
    // Listen to messages
    _messagesSubscription = _chatService
        .getMessages(currentUserId: _userId)
        .listen(_handleMessages);

    // Listen to pending challenges
    if (_userId.isNotEmpty) {
      _challengesSubscription = _chatService
          .getPendingChallenges(_userId)
          .listen(_handleChallenges);
    }
  }

  void _handleMessages(List<Message> messages) {
    if (!mounted) return;

    // On first load, just record the latest timestamp
    if (!_isMessagesInitialized) {
      _isMessagesInitialized = true;
      if (messages.isNotEmpty) {
        _lastMessageTimestamp = messages.last.sent;
      }
      return;
    }

    // Find new messages (sent after our last known timestamp)
    final newMessages = messages.where((m) {
      if (_lastMessageTimestamp == null) return false;
      // Only show messages from others, not from ourselves or system
      if (m.userId == _userId || m.userId == 'system') return false;
      return m.sent.isAfter(_lastMessageTimestamp!);
    }).toList();

    if (newMessages.isNotEmpty) {
      _lastMessageTimestamp = messages.last.sent;

      // Create notifications for new messages
      for (final message in newMessages) {
        final isWhisper = message.toUser != null;
        _addNotification(ChatNotification(
          id: message.id,
          title: isWhisper ? '${message.userName} (whisper)' : message.userName,
          message: message.message,
          type: isWhisper ? NotificationType.whisper : NotificationType.message,
          timestamp: message.sent,
        ));
      }
    }
  }

  void _handleChallenges(List<Challenge> challenges) {
    if (!mounted) return;

    // Find new challenges
    final currentIds = challenges.map((c) => c.id).toSet();
    final newChallenges = challenges.where((c) => !_lastChallengeIds.contains(c.id)).toList();

    // On first load, just record existing challenge IDs without notifying
    if (!_isChallengesInitialized) {
      _isChallengesInitialized = true;
      _lastChallengeIds = currentIds;
      return;
    }

    _lastChallengeIds = currentIds;

    // Create notifications for new challenges
    for (final challenge in newChallenges) {
      _addNotification(ChatNotification(
        id: challenge.id,
        title: challenge.challengerName,
        message: 'Challenged you to ${_getGameTypeName(challenge.gameType)}!',
        type: NotificationType.challenge,
        timestamp: challenge.createdAt,
        challengeId: challenge.id,
      ));
    }
  }

  String _getGameTypeName(GameType gameType) {
    switch (gameType) {
      case GameType.rockPaperScissors:
        return 'Rock Paper Scissors';
      case GameType.reactionTest:
        return 'Reaction Test';
      case GameType.findTheGoat:
        return 'Find the Goat';
    }
  }

  void _addNotification(ChatNotification notification) {
    setState(() {
      _notifications.insert(0, notification);
    });
    _animationController.forward(from: 0);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissNotification(notification.id);
      }
    });
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _onNotificationTap(ChatNotification notification) {
    _dismissNotification(notification.id);
    navigateWithUrlUpdate(context, '/chat');
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _challengesSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_notifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: _notifications.take(3).map((notification) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _NotificationCard(
                      notification: notification,
                      onTap: () => _onNotificationTap(notification),
                      onDismiss: () => _dismissNotification(notification.id),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final ChatNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.whisper:
        return Icons.lock;
      case NotificationType.challenge:
        return Icons.sports_kabaddi;
    }
  }

  Color _getAccentColor(BuildContext context) {
    switch (notification.type) {
      case NotificationType.message:
        return const Color(0xFF00bcd4);
      case NotificationType.whisper:
        return const Color(0xFF9c27b0);
      case NotificationType.challenge:
        return const Color(0xFFff6b35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

