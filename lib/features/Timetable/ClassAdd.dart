// add_course_screen.dart
import 'package:flutter/material.dart';

class ClassAdd extends StatelessWidget {
  const ClassAdd({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('강의 추가'),
      ),
      body: const Center(
        child: Text(
          '강의 추가 페이지입니다.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}