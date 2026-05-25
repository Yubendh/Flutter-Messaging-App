import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart';

class StudyGroup {
  final String id;
  final String name;
  final String description;
  final String courseCode;
  final String subject;
  final String template;
  final int memberCount;
  final int maxMembers;
  final bool isOnline;
  final bool isPublic;
  final String lastMessage;
  final String lastMessageTime;
  final String inviteCode;
  final List<String> tags;
  final String createdBy;
  final Map<String, String> memberRoles;
  final List<String> memberIds;
  final List<String> banList;
  final List<Message> messages;

  const StudyGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.courseCode = '',
    this.subject = '',
    this.template = 'general',
    required this.memberCount,
    this.maxMembers = 20,
    required this.isOnline,
    this.isPublic = true,
    required this.lastMessage,
    required this.lastMessageTime,
    this.inviteCode = '',
    this.tags = const [],
    this.createdBy = '',
    this.memberRoles = const {},
    this.memberIds = const [],
    this.banList = const [],
    required this.messages,
  });

  static String _fmtTime(dynamic raw) {
    if (raw == null) return '';
    final dt = raw is Timestamp ? raw.toDate() : null;
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  factory StudyGroup.fromFirestore(Map<String, dynamic> data) => StudyGroup(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        courseCode: data['courseCode'] as String? ?? '',
        subject: data['subject'] as String? ?? '',
        template: data['template'] as String? ?? 'general',
        memberCount: data['memberCount'] as int? ?? 0,
        maxMembers: data['maxMembers'] as int? ?? 20,
        isOnline: data['isOnline'] as bool? ?? false,
        isPublic: data['isPublic'] as bool? ?? true,
        lastMessage: data['lastMessage'] as String? ?? '',
        lastMessageTime: _fmtTime(data['lastMessageTime']),
        inviteCode: data['inviteCode'] as String? ?? '',
        tags: List<String>.from(data['tags'] as List? ?? []),
        createdBy: data['createdBy'] as String? ?? '',
        memberRoles: Map<String, String>.from(data['memberRoles'] as Map? ?? {}),
        memberIds: List<String>.from(data['memberIds'] as List? ?? []),
        banList: List<String>.from(data['banList'] as List? ?? []),
        messages: [],
      );
}
