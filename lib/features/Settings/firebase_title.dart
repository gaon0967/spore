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

  // firestore 저장
  await docRef.set({
    'unlocked_titles': FieldValue.arrayUnion(newTitles),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await syncFirestoreTitlesToLocal();
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
Future<void> handleNewUserTitle({Function? onUpdate}) async {
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
  }
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
}

// 친구 타이틀 추가
Future<List<TitleInfo>> handleFriendCount(
    int newCount, {
      Function? onUpdate,
    }) async {
  final prefs = await SharedPreferences.getInstance();
  final psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: psychologyCount, // UserStats 때문에 남겨둠
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

// 투두리스트 타이틀 추가
Future<void> TodoTitlesFirestore(List<String> unlockedTitles) async {
  await addUnlockedTitlesToFirestore(unlockedTitles);
}

Future<List<TitleInfo>> handleTodoCount(
    int newCount, {
      Function? onUpdate,
    }) async {
  final stats = UserStats(
    psychologyTestCount: 0,
    todoCount: newCount,
  );

  final todoTitles =
  allTitles.where((t) => t.id.startsWith('todo_')).toList();

  // 로컬에 저장, 획득 목록 받기
  final newlyEarnedTitles =
  await filterAndSaveTitles(stats, todoTitles, onUpdate: onUpdate);

  // firestore에도 반영
  final titleNames = newlyEarnedTitles.map((t) => t.name).toList();
  if (titleNames.isNotEmpty) {
    await addUnlockedTitlesToFirestore(titleNames);
  }

  return newlyEarnedTitles;
}

// 투두 n일 연속 타이틀 추가
Future<List<TitleInfo>> ConstTodoCount(
    int consecutiveDays, {
      Function? onUpdate,
    }) async {
  final stats = UserStats(
    psychologyTestCount: 0,
    consecutiveTodoSuccess: consecutiveDays,
  );

  final streakTitles =
  allTitles.where((t) => t.id.startsWith('streak_')).toList();

  final newlyEarnedTitles =
  await filterAndSaveTitles(stats, streakTitles, onUpdate: onUpdate);

  final titleNames = newlyEarnedTitles.map((t) => t.name).toList();
  if (titleNames.isNotEmpty) {
    await addUnlockedTitlesToFirestore(titleNames);
  }
  return newlyEarnedTitles;
}
// firestore에 저장된 일정으로 연속일수 계산
Future<void> handleConsecutiveTodo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance.collection('plans').doc(user.uid).get();
  final data = doc.data();
  final dateMap = (data?['date'] as Map<String, dynamic>?) ?? {};

  bool isAllDone(String yyyymmdd) {
    final daily = dateMap[yyyymmdd];
    if (daily == null) return false;
    final eventsMap = (daily as Map<String, dynamic>);
    if (eventsMap.isEmpty) return false;
    // 모든 이벤트의 isDone이 true인지 확인
    return eventsMap.values.every((e) => (e as Map<String, dynamic>)['isDone'] == true);
  }

  String toKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  int count = 0;
  DateTime d = DateTime.now().toUtc();
  while (true) {
    final key = toKey(DateTime.utc(d.year, d.month, d.day));
    if (!isAllDone(key)) break;
    count++;
    d = d.subtract(const Duration(days: 1));
  }

  await ConstTodoCount(count);
}
// Firestore에 -> SharedPreferences 동기화
// 타이틀 지급을 위함
Future<void> syncFirestoreTitlesToLocal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final remote = await getUnlockedTitlesFromFirestore();
  final prefs = await SharedPreferences.getInstance();

  await prefs.setStringList('unlocked_titles', remote);
}



// 앱 초기 실행 시 호출(앱 업데이트 시)
// 로컬의 모든 타이틀을 firebase로 한 번만 옮기는 마이그레이션 함수
Future<void> migrateAllLocalTitlesToFirestoreOnce() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final uid = user.uid;

  final prefs = await SharedPreferences.getInstance();
  final migratedKey = 'titles_migrated_$uid';
  if (prefs.getBool(migratedKey) ?? false) {
    return;
  }

  // 서버에 이미 있으면 마이그레이션 스킵
  final remote = await getUnlockedTitlesFromFirestore();
  if (remote.isNotEmpty) {
    await prefs.setBool(migratedKey, true);
    return;
  }

  // UID별 로컬 키만 사용 (이전 계정 잔여분 유입 방지)
  final localKey = 'unlocked_titles_$uid';
  final localTitles = prefs.getStringList(localKey) ?? [];

  if (localTitles.isEmpty) {
    await prefs.setBool(migratedKey, true);
    return;
  }

  // 마이그레이션 기록 저장
  await addUnlockedTitlesToFirestore(localTitles);
  await prefs.setBool(migratedKey, true);
}
