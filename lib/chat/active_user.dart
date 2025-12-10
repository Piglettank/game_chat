import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveUser {
  final String userId;
  final String userName;
  final DateTime lastSeen;

  ActiveUser({
    required this.userId,
    required this.userName,
    required this.lastSeen,
  });

  factory ActiveUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActiveUser(
      userId: doc.id,
      userName: data['userName'] as String? ?? 'Anonymous',
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    // Consider user active if last seen within 2 minutes
    return difference.inMinutes < 2;
  }
}
