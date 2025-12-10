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
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    DateTime lastSeenDate = DateTime.now();
    try {
      final lastSeenValue = data['lastSeen'];
      if (lastSeenValue != null) {
        if (lastSeenValue is Timestamp) {
          lastSeenDate = lastSeenValue.toDate();
        } else if (lastSeenValue is Map) {
          // Handle case where timestamp might be returned as a Map
          final seconds = lastSeenValue['seconds'] as int?;
          final nanoseconds = lastSeenValue['nanoseconds'] as int?;
          if (seconds != null) {
            lastSeenDate = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
            );
          }
        }
      }
    } catch (_) {
      // If anything goes wrong, use current time as fallback
      lastSeenDate = DateTime.now();
    }
    
    return ActiveUser(
      userId: doc.id,
      userName: data['userName'] as String? ?? 'Anonymous',
      lastSeen: lastSeenDate,
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
