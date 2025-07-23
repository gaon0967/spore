import 'package:flutter/material.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 변경'),
      ),
      body: const Center(
        child: Text('프로필 변경 화면'),
      ),
    );
  }
}
