import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  expired,
}

enum GameType {
  rockPaperScissors,
}

enum RockPaperScissorsChoice {
  rock,
  paper,
  scissors,
}

class Challenge {
  final String id;
  final String challengerId;
  final String challengerName;
  final String challengeeId;
  final String challengeeName;
  final GameType gameType;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, String?> choices;
  final Map<String, dynamic>? result;

  Challenge({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    required this.challengeeId,
    required this.challengeeName,
    required this.gameType,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    required this.choices,
    this.result,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Challenge(
      id: doc.id,
      challengerId: data['challengerId'] as String,
      challengerName: data['challengerName'] as String,
      challengeeId: data['challengeeId'] as String,
      challengeeName: data['challengeeName'] as String,
      gameType: GameType.values.firstWhere(
        (e) => e.name == data['gameType'],
        orElse: () => GameType.rockPaperScissors,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ChallengeStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      choices: Map<String, String?>.from(data['choices'] as Map? ?? {}),
      result: data['result'] != null
          ? Map<String, dynamic>.from(data['result'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengerId': challengerId,
      'challengerName': challengerName,
      'challengeeId': challengeeId,
      'challengeeName': challengeeName,
      'gameType': gameType.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'choices': choices,
      'result': result,
    };
  }

  bool get isPending => status == ChallengeStatus.pending;
  bool get isAccepted => status == ChallengeStatus.accepted;
  bool get isInProgress => status == ChallengeStatus.inProgress;
  bool get isCompleted => status == ChallengeStatus.completed;
  
  bool get bothChoicesMade {
    return choices['challenger'] != null && choices['challengee'] != null;
  }

  String? get challengerChoice => choices['challenger'];
  String? get challengeeChoice => choices['challengee'];
}
