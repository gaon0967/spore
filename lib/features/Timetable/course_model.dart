// 불필요 import 제거!
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Course {
  final String id; // null 허용 안 함
  final String title;
  final String professor;
  final String room;
  final int day; 
  final double startTime;
  final double endTime;
  final Color color;

  Course({
    String? id, // 생성 시 id가 없으면 생성
    required this.title,
    required this.professor,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  }) : id = id ?? const Uuid().v4(); // id가 없으면 랜덤 ID 부여

  // Firestore에서 가져올 때
  factory Course.fromMap(Map<String, dynamic> data, String dayId, String docId) {
    final List<String> dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    return Course(
      id: docId, // 여기서 docId는 필드의 key값이 됩니다.
      title: data['title'] ?? '',
      professor: data['professor'] ?? '',
      room: data['room'] ?? '',
      day: dayNames.indexOf(dayId),
      startTime: (data['startTime'] ?? 9).toDouble(),
      endTime: (data['endTime'] ?? 10).toDouble(),
      color: Color(int.parse(data['color'] ?? 'ffddebf1', radix: 16)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'professor': professor,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
      'color': color.value.toRadixString(16),
    };
  }
}