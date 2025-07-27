// lib/features/Timetable/course_model.dart
import 'package:flutter/material.dart';

class Course {
  final String title;
  final String professor;
  final String room;
  final int day;
  final int startTime; // 시(hour) 단위
  final int endTime;   // 시(hour) 단위
  final Color color;

  Course({
    required this.title,
    required this.professor,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}
