import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase 연결 성공!');
  } catch (e) {
    print('❌ Firebase 연결 실패: $e');
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase 연결 확인',
      home: const FirestoreTestScreen(),
    );
  }
}

class FirestoreTestScreen extends StatelessWidget {
  const FirestoreTestScreen({super.key});

  Future<void> _saveTestMessage() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'text': 'Hello Firebase',
        'timestamp': Timestamp.now(),
      });
      print('📥 Firestore에 메시지 저장 성공!');
    } catch (e) {
      print('❌ Firestore 저장 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase 테스트')),
      body: Center(
        child: ElevatedButton(
          onPressed: _saveTestMessage,
          child: const Text('메시지 저장 테스트'),
        ),
      ),
    );
  }
}
