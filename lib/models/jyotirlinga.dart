import 'package:flutter/material.dart';

class JyotirlingaSite {
  final String id;
  final String name;
  final String location;
  final String backstory;
  final Offset mapPosition;

  const JyotirlingaSite({
    required this.id,
    required this.name,
    required this.location,
    required this.backstory,
    required this.mapPosition,
  });

  factory JyotirlingaSite.fromJson(Map<String, dynamic> json) {
    return JyotirlingaSite(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      backstory: json['backstory']?.toString() ?? '',
      mapPosition: Offset(
        (json['map_x'] as num?)?.toDouble() ?? 0,
        (json['map_y'] as num?)?.toDouble() ?? 0,
      ),
    );
  }
}
