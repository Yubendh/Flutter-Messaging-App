import 'package:flutter/material.dart';

class Deadline {
  final String id;
  final DateTime date;
  final String title;
  final String groupId;
  final String groupName;
  final int colorValue;

  Deadline({
    required this.id,
    required this.date,
    required this.title,
    required this.groupId,
    required this.groupName,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  factory Deadline.fromJson(Map<String, dynamic> json) => Deadline(
        id:         json['id']        as String,
        date:       DateTime.parse(json['date'] as String),
        title:      json['title']     as String,
        groupId:    json['groupId']   as String,
        groupName:  json['groupName'] as String,
        colorValue: json['colorValue'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'date':       date.toIso8601String(),
        'title':      title,
        'groupId':    groupId,
        'groupName':  groupName,
        'colorValue': colorValue,
      };
}
