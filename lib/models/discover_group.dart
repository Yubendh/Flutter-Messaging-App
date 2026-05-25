import 'package:flutter/material.dart';

class DiscoverGroup {
  final String id;
  final String courseCode;
  final String subject;
  final int colorValue;
  final int accentColorValue;
  final String name;
  final String description;
  final int memberCount;
  final List<String> filterTags;

  const DiscoverGroup({
    required this.id,
    required this.courseCode,
    required this.subject,
    required this.colorValue,
    required this.accentColorValue,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.filterTags,
  });

  Color get subjectColor  => Color(colorValue);
  Color get accentColor   => Color(accentColorValue);

  factory DiscoverGroup.fromJson(Map<String, dynamic> json) => DiscoverGroup(
        id:               json['id']               as String,
        courseCode:       json['courseCode']        as String,
        subject:          json['subject']           as String,
        colorValue:       json['colorValue']        as int,
        accentColorValue: json['accentColorValue']  as int,
        name:             json['name']              as String,
        description:      json['description']       as String,
        memberCount:      json['memberCount']       as int,
        filterTags:       List<String>.from(json['filterTags'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id':               id,
        'courseCode':       courseCode,
        'subject':          subject,
        'colorValue':       colorValue,
        'accentColorValue': accentColorValue,
        'name':             name,
        'description':      description,
        'memberCount':      memberCount,
        'filterTags':       filterTags,
      };
}
