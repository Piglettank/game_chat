import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String message;
  final DateTime sent;
  final String userId;
  final String userName;
  final String? fromUserName;
  final String? toUser;
  final String? toUserName;

  Message({
    required this.id,
    required this.message,
    required this.sent,
    required this.userId,
    required this.userName,
    this.fromUserName,
    this.toUser,
    this.toUserName,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    DateTime sentDate = DateTime.now();
    try {
      final sentValue = data['sent'];
      if (sentValue != null) {
        if (sentValue is Timestamp) {
          sentDate = sentValue.toDate();
        } else if (sentValue is Map) {
          // Handle case where timestamp might be returned as a Map
          final seconds = sentValue['seconds'] as int?;
          final nanoseconds = sentValue['nanoseconds'] as int?;
          if (seconds != null) {
            sentDate = DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
            );
          }
        }
      }
    } catch (_) {
      // If anything goes wrong, use current time as fallback
      sentDate = DateTime.now();
    }
    
    return Message(
      id: doc.id,
      message: data['message'] as String? ?? '',
      sent: sentDate,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      fromUserName: data['fromUserName'] as String?,
      toUser: data['toUser'] as String?,
      toUserName: data['toUserName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'message': message,
      'sent': Timestamp.fromDate(sent),
      'userId': userId,
      'userName': userName,
    };
    if (fromUserName != null) {
      map['fromUserName'] = fromUserName!;
    }
    if (toUser != null) {
      map['toUser'] = toUser!;
    }
    if (toUserName != null) {
      map['toUserName'] = toUserName!;
    }
    return map;
  }
}
