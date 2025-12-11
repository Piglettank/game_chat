import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart';
import 'active_user.dart';
import '../challenges/challenge.dart';
import '../challenges/game_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String chatId;

  ChatService({required this.chatId});

  CollectionReference get _messagesRef =>
      _firestore.collection('chat').doc(chatId).collection('messages');

  CollectionReference get _activeUsersRef =>
      _firestore.collection('chat').doc(chatId).collection('activeUsers');

  CollectionReference get _challengesRef =>
      _firestore.collection('chat').doc(chatId).collection('challenges');

  Stream<List<Message>> getMessages({String? currentUserId}) {
    return _messagesRef
        .orderBy('sent', descending: false)
        .snapshots()
        .map(
          (snapshot) {
            final allMessages = snapshot.docs
                .map((doc) => Message.fromFirestore(doc))
                .toList();
            
            // Filter whispers: show if currentUserId is the recipient or sender
            if (currentUserId != null) {
              return allMessages.where((message) {
                // Show regular messages (no toUser) to everyone
                if (message.toUser == null) return true;
                // Show whispers to both the recipient and the sender
                return message.toUser == currentUserId || 
                       message.userId == currentUserId;
              }).toList();
            }
            
            return allMessages;
          },
        );
  }

  /// Find user ID by user name from active users
  Future<String?> findUserIdByName(String userName) async {
    final usersSnapshot = await _activeUsersRef.get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final name = data['userName'] as String?;
        if (name != null && name.toLowerCase() == userName.toLowerCase()) {
          return doc.id;
        }
      }
    }
    return null;
  }

  /// Parse whisper command: /w "user name" message
  /// Returns (targetUserId, actualMessage) or null if not a whisper
  Future<Map<String, String>?> _parseWhisperCommand(
    String message,
  ) async {
    final trimmed = message.trim();
    if (!trimmed.startsWith('/w ')) return null;
    
    final rest = trimmed.substring(3).trim();
    if (!rest.startsWith('"')) return null;
    
    final endQuoteIndex = rest.indexOf('"', 1);
    if (endQuoteIndex == -1) return null;
    
    final targetUserName = rest.substring(1, endQuoteIndex);
    final actualMessage = rest.substring(endQuoteIndex + 1).trim();
    
    if (actualMessage.isEmpty) return null;
    
    final targetUserId = await findUserIdByName(targetUserName);
    if (targetUserId == null) return null;
    
    return {
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'message': actualMessage,
    };
  }

  Future<void> sendMessage({
    required String message,
    required String userId,
    required String userName,
  }) async {
    // Check if this is a whisper command
    final whisperData = await _parseWhisperCommand(message);
    
    final messageData = {
      'message': whisperData != null ? whisperData['message'] : message,
      'sent': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': userName,
      'fromUserName': userName,
    };
    
    if (whisperData != null) {
      messageData['toUser'] = whisperData['targetUserId'];
      messageData['toUserName'] = whisperData['targetUserName'];
    }
    
    await _messagesRef.add(messageData);
  }

  /// Add or update user in active users list
  Future<void> joinChat({
    required String userId,
    required String userName,
  }) async {
    await _activeUsersRef.doc(userId).set({
      'userName': userName,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Update user's last seen timestamp (heartbeat)
  Future<void> updateLastSeen(String userId) async {
    await _activeUsersRef.doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Remove user from active users list
  Future<void> leaveChat(String userId) async {
    await _activeUsersRef.doc(userId).delete();
  }

  /// Stream of active users
  Stream<List<ActiveUser>> getActiveUsers() {
    return _activeUsersRef
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActiveUser.fromFirestore(doc))
              .where((user) => user.isActive)
              .toList(),
        );
  }

  /// Create a new challenge
  Future<String> createChallenge({
    required String challengerId,
    required String challengerName,
    required String challengeeId,
    required String challengeeName,
    required GameType gameType,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 5));

    final challengeRef = _challengesRef.doc();

    await challengeRef.set({
      'challengerId': challengerId,
      'challengerName': challengerName,
      'challengeeId': challengeeId,
      'challengeeName': challengeeName,
      'gameType': gameType.name,
      'status': ChallengeStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'choices': {'challenger': null, 'challengee': null},
      'result': null,
    });

    return challengeRef.id;
  }

  /// Accept a challenge
  Future<void> acceptChallenge(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'status': ChallengeStatus.accepted.name,
    });
  }

  /// Reject a challenge
  Future<void> rejectChallenge(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'status': ChallengeStatus.rejected.name,
    });
  }

  /// Make a choice in a challenge
  Future<void> makeChoice({
    required String challengeId,
    required String visitorId,
    required String choice,
  }) async {
    final challengeDoc = await _challengesRef.doc(challengeId).get();
    final challenge = Challenge.fromFirestore(challengeDoc);

    final isChallenger = challenge.challengerId == visitorId;
    final choiceField = isChallenger ? 'challenger' : 'challengee';

    final updateData = <String, dynamic>{'choices.$choiceField': choice};

    // Check if both choices are made after this update
    final newChoices = Map<String, String?>.from(challenge.choices);
    newChoices[choiceField] = choice;

    final bothChoicesMade = newChoices['challenger'] != null && newChoices['challengee'] != null;

    if (bothChoicesMade && isChallenger) {
      // Challenger calculates and saves result
      await _calculateAndSaveResult(
        challengeId: challengeId,
        challenge: challenge,
        newChoices: newChoices,
        updateData: updateData,
      );
    } else {
      // Just save the choice, don't calculate result
      // If challengee makes last choice, challenger's listener will detect and calculate
      updateData['status'] = ChallengeStatus.accepted.name;
      await _challengesRef.doc(challengeId).update(updateData);
    }
  }

  /// Calculate and save result - only called by challenger
  Future<void> calculateResult(String visitorId, String challengeId) async {
    final challengeDoc = await _challengesRef.doc(challengeId).get();
    if (!challengeDoc.exists) return;
    
    final challenge = Challenge.fromFirestore(challengeDoc);
    
    // Only challenger can calculate
    if (challenge.challengerId != visitorId) return;
    
    // Don't recalculate if already completed
    if (challenge.isCompleted || challenge.result != null) return;
    
    // Both choices must be made
    if (!challenge.bothChoicesMade) return;

    final updateData = <String, dynamic>{};
    await _calculateAndSaveResult(
      challengeId: challengeId,
      challenge: challenge,
      newChoices: challenge.choices,
      updateData: updateData,
    );
  }

  Future<void> _calculateAndSaveResult({
    required String challengeId,
    required Challenge challenge,
    required Map<String, String?> newChoices,
    required Map<String, dynamic> updateData,
  }) async {
    final Map<String, dynamic> result;
    if (challenge.gameType == GameType.reactionTest) {
      result = GameService.calculateReactionTestResult(
        challengerChoice: newChoices['challenger']!,
        challengeeChoice: newChoices['challengee']!,
        challengerId: challenge.challengerId,
        challengerName: challenge.challengerName,
        challengeeId: challenge.challengeeId,
        challengeeName: challenge.challengeeName,
      );
    } else if (challenge.gameType == GameType.findTheGoat) {
      result = GameService.calculateFindTheGoatResult(
        challengerChoice: newChoices['challenger']!,
        challengeeChoice: newChoices['challengee']!,
        challengerId: challenge.challengerId,
        challengerName: challenge.challengerName,
        challengeeId: challenge.challengeeId,
        challengeeName: challenge.challengeeName,
      );
    } else {
      result = GameService.calculateRockPaperScissorsResult(
        challengerChoice: newChoices['challenger']!,
        challengeeChoice: newChoices['challengee']!,
        challengerId: challenge.challengerId,
        challengerName: challenge.challengerName,
        challengeeId: challenge.challengeeId,
        challengeeName: challenge.challengeeName,
      );
    }

    updateData['result'] = result;
    updateData['status'] = ChallengeStatus.completed.name;

    await _challengesRef.doc(challengeId).update(updateData);

    // Send result message to chat
    final String resultMessage;
    if (challenge.gameType == GameType.reactionTest) {
      resultMessage = _formatReactionTestResultMessage(
        challengerName: challenge.challengerName,
        challengeeName: challenge.challengeeName,
        result: result,
      );
    } else if (challenge.gameType == GameType.findTheGoat) {
      resultMessage = _formatFindTheGoatResultMessage(
        challengerName: challenge.challengerName,
        challengeeName: challenge.challengeeName,
        result: result,
      );
    } else {
      resultMessage = _formatChallengeResultMessage(
        challengerName: challenge.challengerName,
        challengeeName: challenge.challengeeName,
        challengerChoice: newChoices['challenger']!,
        challengeeChoice: newChoices['challengee']!,
        challengerId: challenge.challengerId,
        result: result,
      );
    }

    await sendMessage(
      message: resultMessage,
      userId: 'system',
      userName: '[Challenge]',
    );
  }

  /// Stream of pending challenges for a user (where they are the challengee)
  Stream<List<Challenge>> getPendingChallenges(String userId) {
    return _challengesRef
        .where('challengeeId', isEqualTo: userId)
        .where('status', isEqualTo: ChallengeStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .toList();
          // Sort by createdAt descending in memory to avoid composite index requirement
          challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return challenges;
        });
  }

  /// Stream of sent challenges for a user (where they are the challenger and status is pending)
  Stream<List<Challenge>> getSentChallenges(String userId) {
    return _challengesRef
        .where('challengerId', isEqualTo: userId)
        .where('status', isEqualTo: ChallengeStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .toList();
          // Sort by createdAt descending in memory to avoid composite index requirement
          challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return challenges;
        });
  }

  /// Stream of active challenges (accepted/in_progress) for a user
  Stream<List<Challenge>> getActiveChallenges(String userId) {
    return _challengesRef
        .where(
          'status',
          whereIn: [
            ChallengeStatus.accepted.name,
            ChallengeStatus.inProgress.name,
          ],
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .where(
                (challenge) =>
                    challenge.challengerId == userId ||
                    challenge.challengeeId == userId,
              )
              .toList(),
        );
  }

  /// Stream of a specific challenge
  Stream<Challenge?> getChallenge(String challengeId) {
    return _challengesRef
        .doc(challengeId)
        .snapshots()
        .map((doc) => doc.exists ? Challenge.fromFirestore(doc) : null);
  }

  String _getChoiceDisplayName(String choice) {
    switch (choice) {
      case 'rock':
        return '✊ rock';
      case 'paper':
        return '✋ paper';
      case 'scissors':
        return '✌️ scissors';
      default:
        return choice;
    }
  }

  String _formatChallengeResultMessage({
    required String challengerName,
    required String challengeeName,
    required String challengerChoice,
    required String challengeeChoice,
    required String challengerId,
    required Map<String, dynamic> result,
  }) {
    final isTie = result['isTie'] as bool? ?? false;

    if (isTie) {
      final choiceDisplay = _getChoiceDisplayName(challengerChoice);
      return '$challengerName and $challengeeName tied with $choiceDisplay!';
    }

    final winnerName = result['winnerName'] as String? ?? 'Unknown';
    final winnerId = result['winnerId'] as String?;
    final loserName = winnerId == challengerId
        ? challengeeName
        : challengerName;

    final winnerChoice = winnerId == challengerId
        ? _getChoiceDisplayName(challengerChoice)
        : _getChoiceDisplayName(challengeeChoice);

    final loserChoice = winnerId == challengerId
        ? _getChoiceDisplayName(challengeeChoice)
        : _getChoiceDisplayName(challengerChoice);

    return '$winnerName beat $loserName with $winnerChoice against $loserChoice!';
  }

  String _formatReactionTestResultMessage({
    required String challengerName,
    required String challengeeName,
    required Map<String, dynamic> result,
  }) {
    final isTie = result['isTie'] as bool? ?? false;
    final challengerTime = result['challengerTime'] as int? ?? 0;
    final challengeeTime = result['challengeeTime'] as int? ?? 0;

    if (isTie) {
      return '⚡ $challengerName and $challengeeName tied with $challengerTime ms reaction time!';
    }

    final winnerName = result['winnerName'] as String? ?? 'Unknown';
    final winnerId = result['winnerId'] as String?;
    final isWinnerChallenger = winnerId == null ? false : (winnerName == challengerName);
    
    final winnerTime = isWinnerChallenger ? challengerTime : challengeeTime;
    final loserName = isWinnerChallenger ? challengeeName : challengerName;
    final loserTime = isWinnerChallenger ? challengeeTime : challengerTime;

    return '⚡ $winnerName beat $loserName in reaction test! ($winnerTime ms vs $loserTime ms)';
  }

  String _formatFindTheGoatResultMessage({
    required String challengerName,
    required String challengeeName,
    required Map<String, dynamic> result,
  }) {
    final isTie = result['isTie'] as bool? ?? false;
    final challengerFound = result['challengerFound'] as bool? ?? false;
    final challengeeFound = result['challengeeFound'] as bool? ?? false;

    if (isTie) {
      if (challengerFound && challengeeFound) {
        return '🐐 $challengerName and $challengeeName both found the goat! It\'s a tie!';
      } else {
        return '🚪 Neither $challengerName nor $challengeeName found the goat!';
      }
    }

    final winnerName = result['winnerName'] as String? ?? 'Unknown';
    final loserName = winnerName == challengerName ? challengeeName : challengerName;

    return '🐐 $winnerName found the goat and beat $loserName!';
  }
}
