import 'package:cloud_firestore/cloud_firestore.dart';

class DirectMessage {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String type;
  final String? content;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileSubtitle;
  final DateTime? timestamp;

  const DirectMessage({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.senderAvatarUrl,
    this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSubtitle,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
      'type': type,
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSubtitle != null) 'fileSubtitle': fileSubtitle,
      'timestamp': timestamp == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(timestamp!),
    };
  }
}
