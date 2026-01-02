import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Settings/TitleHandler.dart';
import 'package:new_project_1/features/Settings/TitleHandler.dart' as titles;
import '../Calendar/Notification.dart';
import '../Calendar/event.dart';

// 공통 타이틀 획득 처리 함수 (알림 생성 + Firestore 저장)
Future<void> _handleTitleAcquisition(List<TitleInfo> newlyEarnedTitles) async {
  if (newlyEarnedTitles.isEmpty) return;
  
  // 새로 획득한 타이틀이 있을 때 알림 생성
  final notificationService = NotificationService();
  for (final title in newlyEarnedTitles) {
    await notificationService.createTitleAcquiredNotification(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      title.name,
    );
  }
  
  // Firestore에 저장
  final names = newlyEarnedTitles.map((t) => t.name).toList();
  await addUnlockedTitlesToFirestore(names);
  await syncFirestoreTitlesToLocal();
  
  // 로컬에만 있는 다른 타이틀들도 함께 Firestore로 동기화
  await syncLocalTitlesToFirestore();
}

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

/// Firestore에 타이틀 추가 (중복 제거)
Future<void> addUnlockedTitlesToFirestore(List<String> newTitles) async {
  if (newTitles.isEmpty) return;
  final docRef = await _userDoc();
  if (docRef == null) return;
  await docRef.set({
    'unlocked_titles': FieldValue.arrayUnion(newTitles),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

// 심리테스트 카운트 증가 (트랜잭션 보장)
Future<int> incrementPsychologyTestCountInFirestore() async {
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



// 로컬 → Firestore로 마이그레이션 (선택사항)
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
    // 새로 획득한 타이틀이 있을 때 알림 생성
    final notificationService = NotificationService();
    await notificationService.createTitleAcquiredNotification(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      title.name,
    );
    
    await addUnlockedTitlesToFirestore([title.name]);
    print('타이틀 획득: ${title.name}');
  }
  print('회원가입 타이틀 저장 완료');
}

// 심리테스트 타이틀 처리
Future<void> SavePsychologyTestCompletion() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final currentTitles = await getUnlockedTitlesFromFirestore();
  final count = await incrementPsychologyTestCountInFirestore();

  List<String> titleIds = [];

  if (count == 1) {
    titleIds = ['spore_family', 'spore_beginner'];
  } else if (count == 2) {
    titleIds = ['spore_detailed_beginner'];
  }

  // 조건에 맞는 TitleInfo 객체만 골라서 필터
  final earnedTitles = allTitles.where((t) => titleIds.contains(t.id)).toList();

  final newlyEarnedTitles = <TitleInfo>[];

  for (final title in earnedTitles) {
    if (!currentTitles.contains(title.name)) {
      newlyEarnedTitles.add(title);
      print('타이틀 획득: ${title.name}');
    }
  }

  if (newlyEarnedTitles.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarnedTitles);
  }
}

// 친구 타이틀 추가
Future<List<TitleInfo>> handleFriendCount(
    int newCount, { Function? onUpdate, }
    ) async {
  final newlyEarned = await handleFriendCountChange(newCount, onUpdate: onUpdate);
  
  if (newlyEarned.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarned);
  }
  
  return newlyEarned;
}

// 투두리스트 타이틀 추가
Future<void> TodoTitlesFirestore(List<String> unlockedTitles) async {
  await addUnlockedTitlesToFirestore(unlockedTitles);
}

Future<List<TitleInfo>> handleTodoCount(
    int newCount, { Function? onUpdate, }
    ) async {
  final newlyEarned = await handleTodoCountTitle(newCount, onUpdate: onUpdate);
  print('🔥 새로 획득한 타이틀: ${newlyEarned.map((t) => t.name).toList()}');
  
  if (newlyEarned.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarned);
  }
  
  return newlyEarned;
}

// 투두 n일 연속 타이틀 추가
Future<List<TitleInfo>> ConstTodoCount(
    int consecutiveDays, { Function? onUpdate, }
    ) async {
  final stats = UserStats(psychologyTestCount: 0, consecutiveTodoSuccess: consecutiveDays);
  final streak = allTitles.where((t) => t.id.startsWith('streak_') && t.condition(stats)).toList();
  
  // 기존에 가지고 있던 타이틀 목록 가져오기
  final currentTitles = await getUnlockedTitlesFromFirestore();
  
  // 새로 획득한 타이틀만 필터링
  final newlyEarnedTitles = streak.where((t) => !currentTitles.contains(t.name)).toList();
  
  if (newlyEarnedTitles.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarnedTitles);
  }
  
  return streak;
}

// 투두리스트 연속 성공 일수 기반 타이틀 처리
Future<List<TitleInfo>> handleConsecutiveTodoSuccessTitleFirestore(
    Map<DateTime, List<Event>> events,
    DateTime referenceDate, {
      Function? onUpdate,
    }) async {
  final newlyEarned = await handleConsecutiveTodoSuccessTitle(events, referenceDate, onUpdate: onUpdate);
  
  if (newlyEarned.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarned);
  }
  
  return newlyEarned;
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
  
  // 투두리스트 개수 타이틀도 함께 처리
  await handleTodoCountFromFirestore();
}

// Firestore에서 투두리스트 개수를 계산하고 타이틀 지급
Future<void> handleTodoCountFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final doc = await FirebaseFirestore.instance.collection('plans').doc(user.uid).get();
  final data = doc.data();
  final dateMap = (data?['date'] as Map<String, dynamic>?) ?? {};
  
  int totalTodoCount = 0;
  
  // 모든 날짜의 투두리스트 개수를 합산 (이름이 같아도 각각 카운트)
  for (final daily in dateMap.values) {
    if (daily is Map<String, dynamic>) {
      final eventsMap = daily as Map<String, dynamic>;
      totalTodoCount += eventsMap.length;
    }
  }
  
  if (totalTodoCount > 0) {
    await handleTodoCount(totalTodoCount);
  }
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

// 즐겨찾기 타이틀 추가
Future<List<TitleInfo>> handleFavoriteFriendTitleFirestore(
    int favoriteCount, { Function? onUpdate, }
    ) async {
  final newlyEarned = await handleFavoriteFriendTitle(favoriteCount, onUpdate: onUpdate);
  
  if (newlyEarned.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarned);
  }
  
  return newlyEarned;
}
// 시간표 타이틀 추가
Future<List<TitleInfo>> handleScheduleCountFirestore(
    int scheduleCount, { Function? onUpdate, }
    ) async {
  final newlyEarned = await handleScheduleCountTitle(scheduleCount, onUpdate: onUpdate);
  
  if (newlyEarned.isNotEmpty) {
    await _handleTitleAcquisition(newlyEarned);
  }
  
  return newlyEarned;
}

// Firestore의 시간표 데이터를 읽어 개수를 계산 → 타이틀 지급
Future<List<TitleInfo>> handleScheduleTitlesFromFirestore({ Function? onUpdate, }) async {
  final count = await getTotalSchedule();
  return handleScheduleCountFirestore(count, onUpdate: onUpdate);
}

Future<List<titles.TitleInfo>> handleProfileEditTitles({
  required bool hasIntro,
  bool hasProfileImage = false,
  Function? onUpdate,
}) async {
  final earned = await titles.handleProfileEditTitles(
    hasIntro: hasIntro,
    onUpdate: onUpdate,
  );

  if (earned.isNotEmpty) {
    await _handleTitleAcquisition(earned);
  }
  
  return earned;
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

  print('심리테스트 타이틀 저장 완료');
}

// 로컬에만 있는 타이틀을 Firestore로 동기화하는 함수
Future<void> syncLocalTitlesToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final prefs = await SharedPreferences.getInstance();
  final localTitles = prefs.getStringList('unlocked_titles') ?? [];
  
  if (localTitles.isEmpty) return;

  final remoteTitles = await getUnlockedTitlesFromFirestore();
  
  // 로컬에만 있는 타이틀 찾기
  final titlesToSync = localTitles.where((title) => !remoteTitles.contains(title)).toList();
  
  if (titlesToSync.isNotEmpty) {
    await addUnlockedTitlesToFirestore(titlesToSync);
    print('로컬 타이틀을 Firestore로 동기화 완료: $titlesToSync');
  }
}
