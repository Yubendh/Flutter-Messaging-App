import 'package:flutter/material.dart';

enum NotificationType { mention, badge, message }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.mention: return Icons.alternate_email;
      case NotificationType.badge:   return Icons.star_rounded;
      case NotificationType.message: return Icons.chat_bubble_outline;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.mention: return const Color(0xFF1565C0);
      case NotificationType.badge:   return const Color(0xFFF97316);
      case NotificationType.message: return const Color(0xFF6B7280);
    }
  }

  String get timeLabel {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours} hours ago';
    if (diff.inDays == 1)    return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id:        json['id']                                  as String,
        type:      NotificationType.values.byName(json['type'] as String),
        title:     json['title']                               as String,
        body:      json['body']                                as String,
        timestamp: DateTime.parse(json['timestamp']           as String),
        isRead:    json['isRead']                              as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'type':      type.name,
        'title':     title,
        'body':      body,
        'timestamp': timestamp.toIso8601String(),
        'isRead':    isRead,
      };
}
