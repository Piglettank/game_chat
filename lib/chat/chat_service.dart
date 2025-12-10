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

  Stream<List<Message>> getMessages() {
    return _messagesRef
        .orderBy('sent', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  Future<void> sendMessage({
    required String message,
    required String userId,
    required String userName,
  }) async {
    await _messagesRef.add({
      'message': message,
      'sent': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': userName,
    });
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
    required String userId,
    required String choice,
  }) async {
    final challengeDoc = await _challengesRef.doc(challengeId).get();
    final challenge = Challenge.fromFirestore(challengeDoc);

    final isChallenger = challenge.challengerId == userId;
    final choiceField = isChallenger ? 'challenger' : 'challengee';

    final updateData = <String, dynamic>{'choices.$choiceField': choice};

    // Check if both choices are made after this update
    final newChoices = Map<String, String?>.from(challenge.choices);
    newChoices[choiceField] = choice;

    if (newChoices['challenger'] != null && newChoices['challengee'] != null) {
      // Both choices made, calculate result
      updateData['status'] = ChallengeStatus.inProgress.name;

      final result = GameService.calculateRockPaperScissorsResult(
        challengerChoice: newChoices['challenger']!,
        challengeeChoice: newChoices['challengee']!,
        challengerId: challenge.challengerId,
        challengerName: challenge.challengerName,
        challengeeId: challenge.challengeeId,
        challengeeName: challenge.challengeeName,
      );

      updateData['result'] = result;
      updateData['status'] = ChallengeStatus.completed.name;

      await _challengesRef.doc(challengeId).update(updateData);

      // Only challenger sends the result message to chat
      if (isChallenger) {
        final resultMessage = _formatChallengeResultMessage(
          challengerName: challenge.challengerName,
          challengeeName: challenge.challengeeName,
          challengerChoice: newChoices['challenger']!,
          challengeeChoice: newChoices['challengee']!,
          challengerId: challenge.challengerId,
          result: result,
        );

        await sendMessage(
          message: resultMessage,
          userId: 'system',
          userName: '[Challenge]',
        );
      }
    } else {
      // Still waiting for other player
      updateData['status'] = ChallengeStatus.accepted.name;
      await _challengesRef.doc(challengeId).update(updateData);
    }
  }

  /// Stream of pending challenges for a user
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
        return '? rock';
      case 'paper':
        return '? paper';
      case 'scissors':
        return '?? scissors';
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
}
