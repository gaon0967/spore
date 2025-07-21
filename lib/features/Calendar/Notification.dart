import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
      ),
      body: const Center(
        child: Text(
          '알림 목록이 여기에 표시됩니다.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}