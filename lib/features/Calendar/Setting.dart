import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: const Center(
        child: Text(
          '여기는 설정 페이지입니다.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}