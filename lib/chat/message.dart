import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String message;
  final DateTime sent;
  final String userId;
  final String userName;

  Message({
    required this.id,
    required this.message,
    required this.sent,
    required this.userId,
    required this.userName,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      message: data['message'] as String,
      sent: (data['sent'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Anonymous',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'sent': Timestamp.fromDate(sent),
      'userId': userId,
      'userName': userName,
    };
  }
}
