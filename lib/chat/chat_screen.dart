import 'dart:async';
import 'package:flutter/material.dart';
import 'message.dart';
import 'active_user.dart';
import 'chat_service.dart';
import '../challenges/challenge.dart';
import '../challenges/challenge_dialog.dart';
import '../challenges/challenge_notification.dart';
import '../challenges/rock_paper_scissors_game.dart';
import '../leaderboard/leaderboard_widget.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatService _chatService;
  Timer? _heartbeatTimer;
  Timer? _completionDelayTimer;
  Challenge? _activeChallenge;
  bool _isUsersMenuOpen = false;
  bool _isLeaderboardEditMode = false;
  final GlobalKey<LeaderboardWidgetState> _leaderboardKey = GlobalKey<LeaderboardWidgetState>();

  // Local message list to prevent full rebuilds
  List<Message> _messages = [];
  List<Challenge> _challenges = [];
  List<ActiveUser> _activeUsers = [];
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<Challenge>>? _activeChallengesSubscription;
  StreamSubscription<List<Challenge>>? _pendingChallengesSubscription;
  StreamSubscription<List<ActiveUser>>? _activeUsersSubscription;
  StreamSubscription<Challenge?>? _currentChallengeSubscription;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(chatId: widget.chatId);
    _joinChat();
    _startHeartbeat();
    _listenToActiveChallenges();
    _listenToMessages();
    _listenToPendingChallenges();
    _listenToActiveUsers();
  }

  void _listenToMessages() {
    _messagesSubscription = _chatService.getMessages().listen((newMessages) {
      if (!mounted) return;

      // Check if messages actually changed (by comparing IDs)
      final previousIds = _messages.map((m) => m.id).toList();
      final newIds = newMessages.map((m) => m.id).toList();
      final messagesChanged =
          previousIds.length != newIds.length ||
          !_listsEqual(previousIds, newIds);

      if (messagesChanged) {
        setState(() {
          _messages = newMessages;
        });

        // With reverse: true, ListView automatically maintains scroll position at bottom
        // No manual scrolling needed
      }
    });
  }

  void _listenToPendingChallenges() {
    _pendingChallengesSubscription = _chatService
        .getPendingChallenges(widget.userId)
        .listen((challenges) {
          if (mounted) {
            setState(() {
              _challenges = challenges;
            });
          }
        });
  }

  void _listenToActiveUsers() {
    _activeUsersSubscription = _chatService.getActiveUsers().listen((newUsers) {
      if (!mounted) return;

      // Check if users actually changed (by comparing IDs)
      final previousIds = _activeUsers.map((u) => u.userId).toList()..sort();
      final newIds = newUsers.map((u) => u.userId).toList()..sort();
      final usersChanged =
          previousIds.length != newIds.length ||
          !_listsEqual(previousIds, newIds);

      if (usersChanged) {
        setState(() {
          _activeUsers = newUsers;
        });
      }
    });
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _completionDelayTimer?.cancel();
    _messagesSubscription?.cancel();
    _activeChallengesSubscription?.cancel();
    _pendingChallengesSubscription?.cancel();
    _activeUsersSubscription?.cancel();
    _currentChallengeSubscription?.cancel();
    _leaveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToActiveChallenges() {
    _activeChallengesSubscription = _chatService.getActiveChallenges(widget.userId).listen((
      challenges,
    ) {
      if (!mounted) return;

      final previousChallengeId = _activeChallenge?.id;
      final newChallenge = challenges.isNotEmpty ? challenges.first : null;
      final newChallengeId = newChallenge?.id;

      // If we're switching to a different challenge, cancel delay timer and subscription
      if (previousChallengeId != null &&
          newChallengeId != null &&
          previousChallengeId != newChallengeId) {
        _completionDelayTimer?.cancel();
        _completionDelayTimer = null;
        _currentChallengeSubscription?.cancel();
        _currentChallengeSubscription = null;
      }

      // If challenge disappeared from active list, check if it completed
      if (previousChallengeId != null &&
          newChallengeId != previousChallengeId) {
        // The challenge disappeared - fetch its latest state to check if it completed
        // Don't cancel subscription yet - let it finish detecting completion if it hasn't already
        _checkChallengeCompletion(previousChallengeId);
        return; // Don't update _activeChallenge yet, wait for completion check
      }

      // Cancel subscription to previous challenge if we're getting a new one
      if (previousChallengeId != newChallengeId) {
        _currentChallengeSubscription?.cancel();
        _currentChallengeSubscription = null;
      }

      // If we have a new challenge, listen to it for real-time updates
      if (newChallenge != null && newChallengeId != previousChallengeId) {
        _listenToChallengeUpdates(newChallengeId!);
      }

      // Update active challenge if no delay timer is running
      if (_completionDelayTimer == null) {
        setState(() {
          _activeChallenge = newChallenge;
        });
      }
    });
  }

  void _listenToChallengeUpdates(String challengeId) {
    _currentChallengeSubscription = _chatService
        .getChallenge(challengeId)
        .listen((challenge) {
          if (!mounted) return;

          if (challenge != null) {
            // Update the challenge object with latest data
            if (_completionDelayTimer == null) {
              setState(() {
                _activeChallenge = challenge;
              });
            }

            // If challenge just completed, start the delay timer
            if (challenge.isCompleted &&
                challenge.result != null &&
                _completionDelayTimer == null) {
              _completionDelayTimer = Timer(const Duration(milliseconds: 2500), () {
                if (mounted) {
                  // After 2 seconds, check if there's a new active challenge
                  _chatService.getActiveChallenges(widget.userId).first.then((
                    challenges,
                  ) {
                    if (mounted) {
                      _completionDelayTimer = null;
                      setState(() {
                        _activeChallenge = challenges.isNotEmpty
                            ? challenges.first
                            : null;
                      });
                    }
                  });
                }
              });
            }
          }
        });
  }

  void _checkChallengeCompletion(String challengeId) {
    // Fetch the latest state of the challenge that disappeared
    _chatService.getChallenge(challengeId).first.then((challenge) {
      if (!mounted) return;

      // Cancel the subscription now that we've checked
      _currentChallengeSubscription?.cancel();
      _currentChallengeSubscription = null;

      if (challenge != null &&
          challenge.isCompleted &&
          challenge.result != null) {
        // Challenge completed - keep it visible for 2 seconds
        // Only start timer if one isn't already running
        if (_completionDelayTimer == null) {
          setState(() {
            _activeChallenge = challenge;
          });

          _completionDelayTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              // After 2.5 seconds, check if there's a new active challenge
              _chatService.getActiveChallenges(widget.userId).first.then((
                challenges,
              ) {
                if (mounted) {
                  _completionDelayTimer = null;
                  setState(() {
                    _activeChallenge = challenges.isNotEmpty
                        ? challenges.first
                        : null;
                  });
                }
              });
            }
          });
        } else {
          // Timer already running, just update the challenge object
          setState(() {
            _activeChallenge = challenge;
          });
        }
      } else {
        // Challenge didn't complete or doesn't exist - clear it immediately
        if (_completionDelayTimer == null) {
          _chatService.getActiveChallenges(widget.userId).first.then((
            challenges,
          ) {
            if (mounted) {
              setState(() {
                _activeChallenge = challenges.isNotEmpty
                    ? challenges.first
                    : null;
              });
            }
          });
        }
      }
    });
  }

  Future<void> _joinChat() async {
    await _chatService.joinChat(
      userId: widget.userId,
      userName: widget.userName,
    );
  }

  Future<void> _leaveChat() async {
    await _chatService.leaveChat(widget.userId);
  }

  void _startHeartbeat() {
    // Update last seen every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _chatService.updateLastSeen(widget.userId);
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    await _chatService.sendMessage(
      message: message,
      userId: widget.userId,
      userName: widget.userName,
    );
    // With reverse: true, new messages automatically appear at bottom
  }

  Future<void> _challengeUser(ActiveUser user) async {
    final gameType = await showDialog<GameType>(
      context: context,
      builder: (context) => ChallengeDialog(challengeeName: user.userName),
    );

    if (gameType != null) {
      await _chatService.createChallenge(
        challengerId: widget.userId,
        challengerName: widget.userName,
        challengeeId: user.userId,
        challengeeName: user.userName,
        gameType: gameType,
      );
    }
  }

  Future<void> _acceptChallenge(Challenge challenge) async {
    await _chatService.acceptChallenge(challenge.id);
  }

  Future<void> _rejectChallenge(Challenge challenge) async {
    await _chatService.rejectChallenge(challenge.id);
  }

  Future<void> _makeChoice(RockPaperScissorsChoice choice) async {
    if (_activeChallenge == null) return;

    await _chatService.makeChoice(
      challengeId: _activeChallenge!.id,
      userId: widget.userId,
      choice: choice.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Leaderboard section (left half)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: _buildLeaderboard(context),
            ),
          ),
          // Chat section (right half)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chat',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  child: _messages.isEmpty && _challenges.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No messages yet. Start the conversation!',
                                          ),
                                        )
                                      : ListView.builder(
                                          key: const ValueKey('messages_list'),
                                          controller: _scrollController,
                                          padding: const EdgeInsets.all(8.0),
                                          itemCount:
                                              _challenges.length + _messages.length,
                                          reverse: true,
                                          addAutomaticKeepAlives: false,
                                          addRepaintBoundaries: true,
                                          itemBuilder: (context, index) {
                                            // Show challenges first (will appear at bottom with reverse: true)
                                            if (index < _challenges.length) {
                                              final challenge = _challenges[index];
                                              return ChallengeNotification(
                                                key: ValueKey(
                                                  'challenge_${challenge.id}',
                                                ),
                                                challenge: challenge,
                                                onAccept: () =>
                                                    _acceptChallenge(challenge),
                                                onReject: () =>
                                                    _rejectChallenge(challenge),
                                              );
                                            }

                                            // Show messages after challenges (will appear at top with reverse: true)
                                            final messageIndex =
                                                index - _challenges.length;
                                            final message =
                                                _messages[_messages.length -
                                                    1 -
                                                    messageIndex];
                                            return _MessageWidget(
                                              key: ValueKey('message_${message.id}'),
                                              message: message,
                                              isOwnMessage:
                                                  message.userId == widget.userId,
                                              formatTimestamp: _formatTimestamp,
                                            );
                                          },
                                        ),
                                ),
                                // Active game UI at the bottom
                                if (_activeChallenge != null)
                                  RockPaperScissorsGame(
                                    challenge: _activeChallenge!,
                                    currentUserId: widget.userId,
                                    onChoiceSelected: _makeChoice,
                                  ),
                              ],
                            ),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: IconButton(
                                icon: Icon(
                                  _isUsersMenuOpen
                                      ? Icons.people
                                      : Icons.people_outline,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isUsersMenuOpen = !_isUsersMenuOpen;
                                  });
                                },
                                tooltip: 'Toggle active users',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isUsersMenuOpen)
                        Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Active Users — ${_activeUsers.length}',
                                      style: Theme.of(context).textTheme.titleSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: _buildActiveUsersList(context)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.7),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          maxLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (_isLeaderboardEditMode) ...[
                IconButton(
                  icon: const Icon(Icons.cancel, size: 20),
                  onPressed: () {
                    _leaderboardKey.currentState?.cancelEdit();
                    setState(() {
                      _isLeaderboardEditMode = false;
                    });
                  },
                  tooltip: 'Cancel editing',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.save, size: 20),
                  onPressed: () {
                    _leaderboardKey.currentState?.saveLeaderboard();
                  },
                  tooltip: 'Save leaderboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      _isLeaderboardEditMode = true;
                    });
                  },
                  tooltip: 'Edit leaderboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
            ],
          ),
        ),
        LeaderboardWidget(
          key: _leaderboardKey,
          isEditMode: _isLeaderboardEditMode,
          onSave: () {
            setState(() {
              _isLeaderboardEditMode = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActiveUsersList(BuildContext context) {
    if (_activeUsers.isEmpty) {
      return Center(
        child: Text(
          'No active users',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    // Sort users: current user first, then others alphabetically
    final sortedUsers = List<ActiveUser>.from(_activeUsers);
    sortedUsers.sort((a, b) {
      final aIsCurrent = a.userId == widget.userId;
      final bIsCurrent = b.userId == widget.userId;

      if (aIsCurrent && !bIsCurrent) return -1;
      if (!aIsCurrent && bIsCurrent) return 1;
      if (aIsCurrent && bIsCurrent) return 0;

      return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
    });

    // Calculate total items: users + potential divider after current user
    final currentUserIndex = sortedUsers.indexWhere(
      (u) => u.userId == widget.userId,
    );
    final hasDivider =
        currentUserIndex != -1 &&
        currentUserIndex < sortedUsers.length - 1 &&
        sortedUsers[currentUserIndex + 1].userId != widget.userId;
    final itemCount = sortedUsers.length + (hasDivider ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: itemCount,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // If this is the divider position (right after current user)
        if (hasDivider && index == currentUserIndex + 1) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            child: CustomPaint(
              painter: _DottedLinePainter(
                color: Theme.of(context).dividerColor,
              ),
              child: const SizedBox(height: 1),
            ),
          );
        }

        // Adjust index if divider was inserted before this user
        final userIndex = hasDivider && index > currentUserIndex + 1
            ? index - 1
            : index;
        final user = sortedUsers[userIndex];
        final isCurrentUser = user.userId == widget.userId;
        final isLastCurrentUser =
            isCurrentUser &&
            (userIndex == sortedUsers.length - 1 ||
                sortedUsers[userIndex + 1].userId != widget.userId);
        final hasDividerAfter = hasDivider && isCurrentUser;

        return _ActiveUserWidget(
          key: ValueKey('user_${user.userId}'),
          user: user,
          isCurrentUser: isCurrentUser,
          isLastCurrentUser: isLastCurrentUser,
          hasDividerAfter: hasDividerAfter,
          onTap: isCurrentUser ? null : () => _challengeUser(user),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _MessageWidget extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final String Function(DateTime) formatTimestamp;

  const _MessageWidget({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.0),
        ),
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage)
              Text(
                message.userName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOwnMessage
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                color: isOwnMessage
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatTimestamp(message.sent),
              style: TextStyle(
                fontSize: 10,
                color: isOwnMessage
                    ? Colors.white70
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveUserWidget extends StatelessWidget {
  final ActiveUser user;
  final bool isCurrentUser;
  final bool isLastCurrentUser;
  final bool hasDividerAfter;
  final VoidCallback? onTap;

  const _ActiveUserWidget({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.isLastCurrentUser,
    this.hasDividerAfter = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.userName,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: isCurrentUser
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isCurrentUser)
              Icon(
                Icons.sports_martial_arts,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
