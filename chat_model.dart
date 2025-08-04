import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String lastMessage;
  final DateTime timestamp;
  final String user1Name;
  final String user2Name;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessage,
    required this.timestamp,
    required this.user1Name,
    required this.user2Name,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      user1Name: data['user1Name'] ?? 'مستخدم',
      user2Name: data['user2Name'] ?? 'مستخدم',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'lastMessage': lastMessage,
      'timestamp': Timestamp.fromDate(timestamp),
      'user1Name': user1Name,
      'user2Name': user2Name,
    };
  }

  // الحصول على اسم المستخدم الآخر
  String getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  // الحصول على ID المستخدم الآخر
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}