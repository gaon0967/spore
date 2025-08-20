import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_project_1/features/Settings/firebase_title.dart';
import 'TitleHandler.dart';

/// 심리테스트 횟수에 따라 타이틀 확인 및 저장
Future<void> SavePsychologyTestCompletion({required int count}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  /* 타이틀 확인 및 저장 틀
Future<void> addUnlockedTitles(List<String> newTitles) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  */

  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await userRef.get();

  List<String> currentTitles = [];
  if (snapshot.exists) {
    final data = snapshot.data();
    if (data != null && data.containsKey('unlocked_titles')) {
      currentTitles = List<String>.from(data['unlocked_titles']);
    }
  }

  // 심테 타이틀 추출
  final stats = UserStats(psychologyTestCount: count);
  final earnedTitles = checkEarnedTitles(stats).where((t) =>
  t.id == 'spore_beginner' || t.id == 'spore_detailed_beginner').toList();

  // 추가한 타이틀 로그
  List<String> newlyAddedTitles = [];

  for (final title in earnedTitles) {
    if (!currentTitles.contains(title.name)) {
      currentTitles.add(title.name);
      newlyAddedTitles.add(title.name); // 콘솔 출력용
    }
  }

  // Firestore에 저장
  await userRef.update({
    'unlocked_titles': currentTitles,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  for (final name in newlyAddedTitles) {
    print('타이틀 획득: $name');
  }

  print('타이틀 저장 완료: $currentTitles');
}