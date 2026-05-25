import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String title;
  final String groupId;
  final String groupName;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String createdBy;

  const StudySession({
    required this.id,
    required this.title,
    required this.groupId,
    required this.groupName,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.createdBy,
  });

  factory StudySession.fromFirestore(String id, Map<String, dynamic> data) {
    return StudySession(
      id: id,
      title: data['title'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      groupName: data['groupName'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'groupId': groupId,
        'groupName': groupName,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        'createdBy': createdBy,
      };
}
