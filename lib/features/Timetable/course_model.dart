// 불필요 import 제거!
import 'package:flutter/material.dart';

class Course {
  final String title;
  final String professor;
  final String room;
  final int day; 
  final double startTime;
  final double endTime;
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

  factory Course.fromMap(Map<String, dynamic> data, String dayId) {
    final List<String> dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    return Course(
      title: data['title'] ?? '',
      professor: data['professor'] ?? '',
      room: data['room'] ?? '',
      day: dayNames.indexOf(dayId),
      startTime: (data['startTime'] ?? 9).toDouble(),
      endTime: (data['endTime'] ?? 10).toDouble(),
      // color를 int로 저장·불러오기!
      color: Color(data['color'] is int 
          ? data['color'] 
          : int.parse(data['color'] ?? 'ffddebf1', radix: 16)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'professor': professor,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
      'color': color.value.toRadixString(16), // hex 문자열

    };
  }
}
