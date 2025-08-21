import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Settings/TitleHandler.dart';

// Firestore에 연결된 사용자 문서 참조 반환
Future<DocumentReference<Map<String, dynamic>>?> _userDoc() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return FirebaseFirestore.instance.collection('users').doc(user.uid);
}

// Firestore에서 타이틀 리스트 가져오기
Future<List<String>> getUnlockedTitlesFromFirestore() async {
  final docRef = await _userDoc();
  if (docRef == null) return [];
  final snapshot = await docRef.get();
  if (!snapshot.exists) return [];
  final data = snapshot.data();
  final list = (data?['unlocked_titles'] as List?) ?? [];
  return list.cast<String>();
}

// Firestore에 타이틀 추가 (중복 제거)
Future<void> addUnlockedTitlesToFirestore(List<String> newTitles) async {
  if (newTitles.isEmpty) return;
  final docRef = await _userDoc();
  if (docRef == null) return;
  await docRef.set({
    'unlocked_titles': FieldValue.arrayUnion(newTitles),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

// 심리테스트 카운트 증가(1회, 2회 구분 위함)
Future<int> incrementPsyCount() async {
  final docRef = await _userDoc();
  if (docRef == null) return 0;
  return FirebaseFirestore.instance.runTransaction((txn) async {
    final snap = await txn.get(docRef);
    final current = (snap.data()?['psychology_test_count'] ?? 0) as int;
    final next = current + 1;
    txn.set(docRef, {
      'psychology_test_count': next,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return next;
  });
}

// 회원가입 타이틀 추가
// 로컬 → Firestore로 마이그레이션(회원가입 시)
Future<void> handleNewUserTitle() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final currentTitles = await getUnlockedTitlesFromFirestore();

  final stats = UserStats(isNewUser: true, psychologyTestCount: 0);
  final title = allTitles.firstWhere(
        (t) => t.id == 'spore_family',
    orElse: () => TitleInfo(id: '', name: '', condition: (_) => false),
  );

  if (title.id.isNotEmpty &&
      title.condition(stats) &&
      !currentTitles.contains(title.name)) {
    await addUnlockedTitlesToFirestore([title.name]);
    print('타이틀 획득: ${title.name}');
  }
  print('회원가입 타이틀 저장 완료');
}

// 심리테스트 타이틀 추가
Future<void> PsychologyTestCompletion() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final currentTitles = await getUnlockedTitlesFromFirestore();
  final count = await incrementPsyCount();

  List<String> titleIds = [];

  if (count == 1) {
    titleIds = ['spore_family', 'spore_beginner'];
  } else if (count == 2) {
    titleIds = ['spore_detailed_beginner'];
  }

  // 조건에 맞는 TitleInfo 객체만 골라서 필터
  final earnedTitles = allTitles.where((t) => titleIds.contains(t.id)).toList();

  final newlyEarnedTitles = <String>[];

  for (final title in earnedTitles) {
    if (!currentTitles.contains(title.name)) {
      newlyEarnedTitles.add(title.name);
      print('타이틀 획득: ${title.name}');
    }
  }

  if (newlyEarnedTitles.isNotEmpty) {
    await addUnlockedTitlesToFirestore(newlyEarnedTitles);
  }

  print('심리테스트 타이틀 저장 완료');
}

// 친구 타이틀 추가
Future<List<TitleInfo>> handleFriendCount(
    int newCount, {
      Function? onUpdate,
    }) async {
  final prefs = await SharedPreferences.getInstance();
  int psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: 0, // UserStats 때문에 남겨둠
    friendsCount: newCount,
  );

  // 친구 관련 타이틀 불러오기
  final friendTitles =
  allTitles.where((t) => t.id.startsWith('friend_')).toList();

  final newlyEarnedTitles =
  await filterAndSaveTitles(stats, friendTitles, onUpdate: onUpdate);

  // Firestore에도 저장
  final titleNames = newlyEarnedTitles.map((t) => t.name).toList();
  if (titleNames.isNotEmpty) {
    await addUnlockedTitlesToFirestore(titleNames);
  }

  return newlyEarnedTitles;
}

// 앱 초기 실행 시 호출(앱 업데이트 시)
// 로컬의 모든 타이틀을 firebase로 한 번만 옮기는 마이그레이션 함수
Future<void> migrateAllLocalTitlesToFirestoreOnce() async {
  final prefs = await SharedPreferences.getInstance();
  final migrated = prefs.getBool('titles_migrated') ?? false;
  if (migrated) {
    print('✅ 이미 마이그레이션 완료됨.');
    return;
  }

  final localTitles = prefs.getStringList('unlocked_titles') ?? [];
  if (localTitles.isEmpty) {
    print('🔥 로컬 타이틀 없음.');
    return;
  }

  await addUnlockedTitlesToFirestore(localTitles);
  await prefs.setBool('titles_migrated', true);
  print('✅ 마이그레이션 완료 및 기록 저장됨.');
}
