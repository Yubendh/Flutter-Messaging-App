import 'package:cloud_firestore/cloud_firestore.dart';

class DirectMessageConversation {
  final String id;
  final List<String> participantIds;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  const DirectMessageConversation({
    required this.id,
    required this.participantIds,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    this.otherUserAvatarUrl,
    this.lastMessageTime,
    this.createdAt,
  });

  factory DirectMessageConversation.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final participants = List<String>.from(data['participantIds'] as List? ?? []);
    return DirectMessageConversation(
      id: id,
      participantIds: participants,
      otherUserId: data['otherUserId'] as String? ?? '',
      otherUserName: data['otherUserName'] as String? ?? 'Unknown',
      otherUserAvatarUrl: data['otherUserAvatarUrl'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: _asDateTime(data['lastMessageTime']),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      if (otherUserAvatarUrl != null) 'otherUserAvatarUrl': otherUserAvatarUrl,
      'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': Timestamp.fromDate(lastMessageTime!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
