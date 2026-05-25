import 'package:flutter/material.dart';

class SuggestedGroup {
  final String id;
  final String subject;
  final int colorValue;
  final String iconName;
  final String name;
  final String description;
  final List<String> badges;

  const SuggestedGroup({
    required this.id,
    required this.subject,
    required this.colorValue,
    required this.iconName,
    required this.name,
    required this.description,
    required this.badges,
  });

  Color get color => Color(colorValue);

  static const Map<String, IconData> _iconMap = {
    'functions':   Icons.functions,
    'psychology':  Icons.psychology_outlined,
    'nightlight':  Icons.nightlight_round,
    'science':     Icons.science_outlined,
    'code':        Icons.code,
    'calculate':   Icons.calculate_outlined,
    'group':       Icons.group_outlined,
  };

  IconData get icon => _iconMap[iconName] ?? Icons.group_outlined;

  factory SuggestedGroup.fromJson(Map<String, dynamic> json) => SuggestedGroup(
        id:          json['id']          as String,
        subject:     json['subject']     as String,
        colorValue:  json['colorValue']  as int,
        iconName:    json['iconName']    as String,
        name:        json['name']        as String,
        description: json['description'] as String,
        badges:      List<String>.from(json['badges'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'subject':     subject,
        'colorValue':  colorValue,
        'iconName':    iconName,
        'name':        name,
        'description': description,
        'badges':      badges,
      };
}
