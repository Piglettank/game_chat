import 'dart:async';
import 'package:flutter/material.dart';
import 'message.dart';
import 'active_user.dart';
import 'chat_service.dart';
import '../challenges/challenge.dart';
import '../challenges/challenge_dialog.dart';
import '../challenges/challenge_notification.dart';
import '../challenges/rock_paper_scissors_game.dart';
import '../challenges/reaction_test_game.dart';
import '../core/app_header.dart';
import '../core/toolbar_button.dart';
import '../core/tab_title.dart';

mixin ChatMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late ChatService chatService;
  Timer? heartbeatTimer;
  Timer? completionDelayTimer;
  Challenge? activeChallenge;
  bool isUsersMenuOpen = false;

  // Local message list to prevent full rebuilds
  List<Message> messages = [];
  List<Challenge> challenges = [];
  List<ActiveUser> activeUsers = [];
  StreamSubscription<List<Message>>? messagesSubscription;
  StreamSubscription<List<Challenge>>? activeChallengesSubscription;
  StreamSubscription<List<Challenge>>? pendingChallengesSubscription;
  StreamSubscription<List<ActiveUser>>? activeUsersSubscription;
  StreamSubscription<Challenge?>? currentChallengeSubscription;

  String get chatId;
  String get userId;
  String get userName;

  void initializeChat() {
    chatService = ChatService(chatId: chatId);
    joinChat();
    startHeartbeat();
    listenToActiveChallenges();
    listenToMessages();
    listenToPendingChallenges();
    listenToActiveUsers();
  }

  void disposeChat() {
    heartbeatTimer?.cancel();
    completionDelayTimer?.cancel();
    messagesSubscription?.cancel();
    activeChallengesSubscription?.cancel();
    pendingChallengesSubscription?.cancel();
    activeUsersSubscription?.cancel();
    currentChallengeSubscription?.cancel();
    leaveChat();
    messageController.dispose();
    scrollController.dispose();
  }

  void listenToMessages() {
    messagesSubscription = chatService.getMessages().listen((newMessages) {
      if (!mounted) return;

      final previousIds = messages.map((m) => m.id).toList();
      final newIds = newMessages.map((m) => m.id).toList();
      final messagesChanged =
          previousIds.length != newIds.length ||
          !_listsEqual(previousIds, newIds);

      if (messagesChanged) {
        setState(() {
          messages = newMessages;
        });
      }
    });
  }

  void listenToPendingChallenges() {
    pendingChallengesSubscription = chatService
        .getPendingChallenges(userId)
        .listen((challenges) {
          if (mounted) {
            setState(() {
              this.challenges = challenges;
            });
          }
        });
  }

  void listenToActiveUsers() {
    activeUsersSubscription = chatService.getActiveUsers().listen((newUsers) {
      if (!mounted) return;

      final previousIds = activeUsers.map((u) => u.userId).toList()..sort();
      final newIds = newUsers.map((u) => u.userId).toList()..sort();
      final usersChanged =
          previousIds.length != newIds.length ||
          !_listsEqual(previousIds, newIds);

      if (usersChanged) {
        setState(() {
          activeUsers = newUsers;
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

  void listenToActiveChallenges() {
    activeChallengesSubscription = chatService.getActiveChallenges(userId).listen((
      challenges,
    ) {
      if (!mounted) return;

      final previousChallengeId = activeChallenge?.id;
      final newChallenge = challenges.isNotEmpty ? challenges.first : null;
      final newChallengeId = newChallenge?.id;

      if (previousChallengeId != null &&
          newChallengeId != null &&
          previousChallengeId != newChallengeId) {
        completionDelayTimer?.cancel();
        completionDelayTimer = null;
        currentChallengeSubscription?.cancel();
        currentChallengeSubscription = null;
      }

      if (previousChallengeId != null &&
          newChallengeId != previousChallengeId) {
        checkChallengeCompletion(previousChallengeId);
        return;
      }

      if (previousChallengeId != newChallengeId) {
        currentChallengeSubscription?.cancel();
        currentChallengeSubscription = null;
      }

      if (newChallenge != null && newChallengeId != previousChallengeId) {
        listenToChallengeUpdates(newChallengeId!);
      }

      if (completionDelayTimer == null) {
        setState(() {
          activeChallenge = newChallenge;
        });
      }
    });
  }

  void listenToChallengeUpdates(String challengeId) {
    currentChallengeSubscription = chatService
        .getChallenge(challengeId)
        .listen((challenge) {
          if (!mounted) return;

          if (challenge != null) {
            if (completionDelayTimer == null) {
              setState(() {
                activeChallenge = challenge;
              });
            }

            if (challenge.isCompleted &&
                challenge.result != null &&
                completionDelayTimer == null) {
              completionDelayTimer = Timer(const Duration(milliseconds: 2500), () {
                if (mounted) {
                  chatService.getActiveChallenges(userId).first.then((
                    challenges,
                  ) {
                    if (mounted) {
                      completionDelayTimer = null;
                      setState(() {
                        activeChallenge = challenges.isNotEmpty
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

  void checkChallengeCompletion(String challengeId) {
    chatService.getChallenge(challengeId).first.then((challenge) {
      if (!mounted) return;

      currentChallengeSubscription?.cancel();
      currentChallengeSubscription = null;

      if (challenge != null &&
          challenge.isCompleted &&
          challenge.result != null) {
        if (completionDelayTimer == null) {
          setState(() {
            activeChallenge = challenge;
          });

          completionDelayTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              chatService.getActiveChallenges(userId).first.then((
                challenges,
              ) {
                if (mounted) {
                  completionDelayTimer = null;
                  setState(() {
                    activeChallenge = challenges.isNotEmpty
                        ? challenges.first
                        : null;
                  });
                }
              });
            }
          });
        } else {
          setState(() {
            activeChallenge = challenge;
          });
        }
      } else {
        if (completionDelayTimer == null) {
          chatService.getActiveChallenges(userId).first.then((
            challenges,
          ) {
            if (mounted) {
              setState(() {
                activeChallenge = challenges.isNotEmpty
                    ? challenges.first
                    : null;
              });
            }
          });
        }
      }
    });
  }

  Future<void> joinChat() async {
    await chatService.joinChat(
      userId: userId,
      userName: userName,
    );
  }

  Future<void> leaveChat() async {
    await chatService.leaveChat(userId);
  }

  void startHeartbeat() {
    heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      chatService.updateLastSeen(userId);
    });
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    messageController.clear();
    await chatService.sendMessage(
      message: message,
      userId: userId,
      userName: userName,
    );
  }

  Future<void> challengeUser(ActiveUser user) async {
    final gameType = await showDialog<GameType>(
      context: context,
      builder: (context) => ChallengeDialog(challengeeName: user.userName),
    );

    if (gameType != null) {
      await chatService.createChallenge(
        challengerId: userId,
        challengerName: userName,
        challengeeId: user.userId,
        challengeeName: user.userName,
        gameType: gameType,
      );
    }
  }

  Future<void> acceptChallenge(Challenge challenge) async {
    await chatService.acceptChallenge(challenge.id);
  }

  Future<void> rejectChallenge(Challenge challenge) async {
    await chatService.rejectChallenge(challenge.id);
  }

  Future<void> makeChoice(RockPaperScissorsChoice choice) async {
    if (activeChallenge == null) return;

    await chatService.makeChoice(
      challengeId: activeChallenge!.id,
      userId: userId,
      choice: choice.name,
    );
  }

  Future<void> makeReactionChoice(String reactionTimeMs) async {
    if (activeChallenge == null) return;

    await chatService.makeChoice(
      challengeId: activeChallenge!.id,
      userId: userId,
      choice: reactionTimeMs,
    );
  }

  String formatTimestamp(DateTime timestamp) {
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

  Widget buildChatSection(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          icon: Icons.chat,
          title: 'Chat',
          actions: [
            ToolbarButton(
              icon: isUsersMenuOpen
                  ? Icons.people
                  : Icons.people_outline,
              label: 'Users',
              onTap: () {
                setState(() {
                  isUsersMenuOpen = !isUsersMenuOpen;
                });
              },
            ),
          ],
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
                          child: messages.isEmpty && challenges.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No messages yet. Start the conversation!',
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('messages_list'),
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount:
                                      challenges.length + messages.length,
                                  reverse: true,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  itemBuilder: (context, index) {
                                    if (index < challenges.length) {
                                      final challenge = challenges[index];
                                      return ChallengeNotification(
                                        key: ValueKey(
                                          'challenge_${challenge.id}',
                                        ),
                                        challenge: challenge,
                                        onAccept: () =>
                                            acceptChallenge(challenge),
                                        onReject: () =>
                                            rejectChallenge(challenge),
                                      );
                                    }

                                    final messageIndex =
                                        index - challenges.length;
                                    final message =
                                        messages[messages.length -
                                            1 -
                                            messageIndex];
                                    return _MessageWidget(
                                      key: ValueKey('message_${message.id}'),
                                      message: message,
                                      isOwnMessage:
                                          message.userId == userId,
                                      formatTimestamp: formatTimestamp,
                                    );
                                  },
                                ),
                        ),
                        if (activeChallenge != null)
                          activeChallenge!.gameType == GameType.reactionTest
                              ? ReactionTestGame(
                                  challenge: activeChallenge!,
                                  currentUserId: userId,
                                  onReactionTimeRecorded: makeReactionChoice,
                                )
                              : RockPaperScissorsGame(
                                  challenge: activeChallenge!,
                                  currentUserId: userId,
                                  onChoiceSelected: makeChoice,
                                ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isUsersMenuOpen)
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
                              'Active Users — ${activeUsers.length}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: buildActiveUsersList(context)),
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
                  controller: messageController,
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
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 8.0),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: sendMessage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00bcd4).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF00bcd4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 20,
                      color: Color(0xFF00bcd4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActiveUsersList(BuildContext context) {
    if (activeUsers.isEmpty) {
      return Center(
        child: Text(
          'No active users',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final sortedUsers = List<ActiveUser>.from(activeUsers);
    sortedUsers.sort((a, b) {
      final aIsCurrent = a.userId == userId;
      final bIsCurrent = b.userId == userId;

      if (aIsCurrent && !bIsCurrent) return -1;
      if (!aIsCurrent && bIsCurrent) return 1;
      if (aIsCurrent && bIsCurrent) return 0;

      return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
    });

    final currentUserIndex = sortedUsers.indexWhere(
      (u) => u.userId == userId,
    );
    final hasDivider =
        currentUserIndex != -1 &&
        currentUserIndex < sortedUsers.length - 1 &&
        sortedUsers[currentUserIndex + 1].userId != userId;
    final itemCount = sortedUsers.length + (hasDivider ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: itemCount,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
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

        final userIndex = hasDivider && index > currentUserIndex + 1
            ? index - 1
            : index;
        final user = sortedUsers[userIndex];
        final isCurrentUser = user.userId == userId;
        final isLastCurrentUser =
            isCurrentUser &&
            (userIndex == sortedUsers.length - 1 ||
                sortedUsers[userIndex + 1].userId != userId);
        final hasDividerAfter = hasDivider && isCurrentUser;

        return _ActiveUserWidget(
          key: ValueKey('user_${user.userId}'),
          user: user,
          isCurrentUser: isCurrentUser,
          isLastCurrentUser: isLastCurrentUser,
          hasDividerAfter: hasDividerAfter,
          onTap: isCurrentUser ? null : () => challengeUser(user),
        );
      },
    );
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
