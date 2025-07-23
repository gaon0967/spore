import 'package:flutter/material.dart';

class friend_management extends StatelessWidget {
  const friend_management({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
      ),
      body: const Center(
        child: Text('친구 관리 화면'),
      ),
    );
  }
}
