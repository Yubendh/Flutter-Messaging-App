import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String? priority;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? dueDate;
  final bool isCompleted;
  final String createdBy;
  final DateTime createdAt;

  final String? groupId;
  final String? groupName;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority,
    this.assignedTo,
    this.assignedToName,
    this.dueDate,
    required this.isCompleted,
    required this.createdBy,
    required this.createdAt,
    this.groupId,
    this.groupName,
  });

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      priority: data['priority'] as String?,
      assignedTo: data['assignedTo'] as String?,
      assignedToName: data['assignedToName'] as String?,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      groupId: data['groupId'] as String?,
      groupName: data['groupName'] as String?,
    );
  }
}
