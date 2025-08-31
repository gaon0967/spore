// lib/event.dart

import 'package:flutter/material.dart';

// 일정을 표현하기 위한 데이터 클래스
class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  bool isCompleted;
  String? id;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCompleted = false,
    this.id,
  });
}