import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/active_user.dart';
import '../models/challenge.dart';
import '../services/chat_service.dart';
import '../widgets/challenge_dialog.dart';
import '../widgets/challenge_notification.dart';
import '../widgets/challenge_result_message.dart';
import '../widgets/rock_paper_scissors_game.dart';

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
  Challenge? _activeChallenge;
  List<Challenge> _previousChallenges = [];
  bool _isUsersMenuOpen = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(chatId: widget.chatId);
    _joinChat();
    _startHeartbeat();
    _listenToActiveChallenges();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _leaveChat();
    _messageController.dispose();
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

  void _listenToActiveChallenges() {
    _chatService.getActiveChallenges(widget.userId).listen((challenges) {
      if (challenges.isNotEmpty) {
        setState(() {
          _activeChallenge = challenges.first;
        });
      } else {
        setState(() {
          _activeChallenge = null;
        });
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
  }

  Future<void> _challengeUser(ActiveUser user) async {
    final gameType = await showDialog<GameType>(
      context: context,
      builder: (context) => ChallengeDialog(
        challengeeName: user.userName,
      ),
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
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Active game UI
                          if (_activeChallenge != null)
                            RockPaperScissorsGame(
                              challenge: _activeChallenge!,
                              currentUserId: widget.userId,
                              onChoiceSelected: _makeChoice,
                            ),
                          Expanded(
                            child: StreamBuilder<List<Message>>(
                              stream: _chatService.getMessages(),
                              builder: (context, messagesSnapshot) {
                                return StreamBuilder<List<Challenge>>(
                                  stream: _chatService.getPendingChallenges(widget.userId),
                                  builder: (context, challengesSnapshot) {
                                    return StreamBuilder<List<Challenge>>(
                                      stream: _chatService.getCompletedChallenges(widget.userId),
                                      builder: (context, completedChallengesSnapshot) {
                                        if (messagesSnapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            challengesSnapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            completedChallengesSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                          return const Center(
                                              child: CircularProgressIndicator());
                                        }

                                        if (messagesSnapshot.hasError) {
                                          return Center(
                                              child: Text('Error: ${messagesSnapshot.error}'));
                                        }

                                        if (challengesSnapshot.hasError) {
                                          debugPrint(
                                              'Error loading pending challenges: ${challengesSnapshot.error}');
                                        }

                                        if (completedChallengesSnapshot.hasError) {
                                          debugPrint(
                                              'Error loading completed challenges: ${completedChallengesSnapshot.error}');
                                        }

                                        final messages = messagesSnapshot.data ?? [];
                                        final challenges = challengesSnapshot.data ?? [];
                                        final completedChallenges =
                                            completedChallengesSnapshot.data ?? [];

                                        // Scroll to bottom when new challenges appear or when ListView first builds
                                        final hasNewChallenges = challenges.isNotEmpty &&
                                            (challenges.length != _previousChallenges.length ||
                                                (_previousChallenges.isEmpty &&
                                                    challenges.isNotEmpty));
                                        if (hasNewChallenges) {
                                          _previousChallenges = List.from(challenges);
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            _scrollToBottom();
                                          });
                                        } else if (challenges.length !=
                                            _previousChallenges.length) {
                                          _previousChallenges = List.from(challenges);
                                        }

                                        if (messages.isEmpty &&
                                            challenges.isEmpty &&
                                            completedChallenges.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No messages yet. Start the conversation!',
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          controller: _scrollController,
                                          padding: const EdgeInsets.all(8.0),
                                          itemCount: messages.length +
                                              completedChallenges.length +
                                              challenges.length,
                                          itemBuilder: (context, index) {
                                            // Show pending challenges at the bottom (end of list)
                                            if (index >=
                                                messages.length +
                                                    completedChallenges.length) {
                                              final challengeIndex = index -
                                                  messages.length -
                                                  completedChallenges.length;
                                              final challenge = challenges[challengeIndex];
                                              return ChallengeNotification(
                                                challenge: challenge,
                                                onAccept: () =>
                                                    _acceptChallenge(challenge),
                                                onReject: () =>
                                                    _rejectChallenge(challenge),
                                              );
                                            }

                                            // Show completed challenges after messages
                                            if (index >= messages.length) {
                                              final completedIndex =
                                                  index - messages.length;
                                              final challenge =
                                                  completedChallenges[completedIndex];
                                              return ChallengeResultMessage(
                                                challenge: challenge,
                                              );
                                            }

                                            // Show messages
                                            final message = messages[index];
                                            final isOwnMessage = message.userId == widget.userId;

                                            return Align(
                                              alignment: isOwnMessage
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(
                                                  vertical: 4.0,
                                                  horizontal: 8.0,
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16.0,
                                                  vertical: 10.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isOwnMessage
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(16.0),
                                                ),
                                                constraints: BoxConstraints(
                                                  minWidth: 120,
                                                  maxWidth: MediaQuery.of(context).size.width *
                                                      0.7,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (!isOwnMessage)
                                                      Text(
                                                        message.userName,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: isOwnMessage
                                                              ? Colors.white
                                                              : Theme.of(
                                                                  context,
                                                                ).colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      message.message,
                                                      style: TextStyle(
                                                        color: isOwnMessage
                                                            ? Colors.white
                                                            : Theme.of(
                                                                context,
                                                              ).colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatTimestamp(message.sent),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isOwnMessage
                                                            ? Colors.white70
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant
                                                                .withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8.0,
                        right: 8.0,
                        child: IconButton(
                          icon: Icon(_isUsersMenuOpen ? Icons.people : Icons.people_outline),
                          onPressed: () {
                            setState(() {
                              _isUsersMenuOpen = !_isUsersMenuOpen;
                            });
                          },
                          tooltip: 'Toggle active users',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: StreamBuilder<List<ActiveUser>>(
                      stream: _chatService.getActiveUsers(),
                      builder: (context, snapshot) {
                        final activeUsers = snapshot.data ?? [];
                        final userCount = activeUsers.length;

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
                                    Icons.people,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Users — $userCount',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _buildActiveUsersList(context, snapshot),
                            ),
                          ],
                        );
                      },
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
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersList(BuildContext context, AsyncSnapshot<List<ActiveUser>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error loading users',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final activeUsers = snapshot.data ?? [];

    if (activeUsers.isEmpty) {
      return Center(
        child: Text(
          'No active users',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    // Sort users: current user first, then others alphabetically
    final sortedUsers = List<ActiveUser>.from(activeUsers);
    sortedUsers.sort((a, b) {
      final aIsCurrent = a.userId == widget.userId;
      final bIsCurrent = b.userId == widget.userId;
      
      if (aIsCurrent && !bIsCurrent) return -1;
      if (!aIsCurrent && bIsCurrent) return 1;
      if (aIsCurrent && bIsCurrent) return 0;
      
      return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        final isCurrentUser = user.userId == widget.userId;
        final isLastCurrentUser = isCurrentUser && 
            (index == sortedUsers.length - 1 || 
             sortedUsers[index + 1].userId != widget.userId);

        return InkWell(
          onTap: isCurrentUser
              ? null
              : () => _challengeUser(user),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            margin: EdgeInsets.only(
              bottom: isLastCurrentUser ? 24.0 : 8.0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
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
