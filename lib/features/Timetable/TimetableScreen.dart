// TimetableScreen.dart
import 'package:flutter/material.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('시간표'),
      ),
      body: Center(
        child: Text('여기 시간표 표시'),
      ),
    );
  }
}
