
import 'package:flutter/material.dart';

class HomeCalendar extends StatelessWidget {
  const HomeCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("메인 화면")),
      body: const Center(
        child: Text(
          "로그인 성공!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}