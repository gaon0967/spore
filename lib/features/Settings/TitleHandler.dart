import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_project_1/features/Calendar/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
/// ==============================
/// 클래스명: UserStats
/// 역할: 유저의 다양한 상태 정보를 담는 모델
/// 사용된 필드: 심리테스트 횟수, 친구 수, 투두리스트 개수 등
/// 관련 기능: 타이틀 획득 조건 검사에 사용
/// ==============================
class UserStats {
  final int psychologyTestCount; // 심리테스트 횟수
  final bool isNewUser; // 회원가입 직후 여부
  final int friendsCount; // 친구 수
  final bool hasIntro; // 자기소개 존재 여부
  final bool hasProfileImage; // 프로필 사진 존재 여부
  final int messageCount; // 메시지 보낸 개수
  final int todoCount; // 투두리스트 개수
  final int consecutiveTodoSuccess; // 투두리스트 N일 연속

  UserStats({
    required this.psychologyTestCount,
    this.isNewUser = false,
    this.friendsCount = 0,
    this.hasIntro = false,
    this.hasProfileImage = false,
    this.messageCount = 0,
    this.todoCount = 0,
    this.consecutiveTodoSuccess = 0,
  });
}

/// ==============================
/// 클래스명: TitleInfo
/// 역할: 타이틀 정보를 담는 모델
/// 사용된 필드: 타이틀 ID, 이름, 획득 조건 함수
/// 관련 기능: 유저 상태에 따라 타이틀 획득 여부 결정
/// ==============================
class TitleInfo {
  final String id; // 타이틀 고유 ID
  final String name; // 타이틀 이름
  final bool Function(UserStats) condition; // 타이틀 획득 조건 함수

  TitleInfo({required this.id, required this.name, required this.condition});
}

/// 전체 타이틀 목록
final allTitles = [
  // 심리테스트
  TitleInfo(
    id: 'spore_beginner',
    name: '스포어의 비기너',
    condition: (stats) => stats.psychologyTestCount >= 1,
  ),
  TitleInfo(
    id: 'spore_detailed_beginner',
    name: '스포어의 꼼꼼한 비기너',
    condition: (stats) => stats.psychologyTestCount >= 2,
  ),

  // 회원가입
  TitleInfo(
    id: 'spore_family',
    name: '스포어의 식구',
    condition: (stats) => stats.isNewUser,
  ),

  // 친구 맺기
  TitleInfo(
    id: 'friend_unique',
    name: '유일무이',
    condition: (stats) => stats.friendsCount >= 1,
  ),
  TitleInfo(
    id: 'friend_popular',
    name: '인싸',
    condition: (stats) => stats.friendsCount >= 5,
  ),
  TitleInfo(
    id: 'friend_super_popular',
    name: '어딜가든 인싸',
    condition: (stats) => stats.friendsCount >= 10,
  ),
  TitleInfo(
    id: 'friend_famous',
    name: '유명인사',
    condition: (stats) => stats.friendsCount >= 20,
  ),

  // 프로필 관련
  TitleInfo(
    id: 'intro_writer',
    name: '자기소개러',
    condition: (stats) => stats.hasIntro,
  ),
  TitleInfo(
    id: 'photo_sharer',
    name: '사진 공유러',
    condition: (stats) => stats.hasProfileImage,
  ),
  TitleInfo(
    id: 'pro_pr',
    name: '자기 PR의 PRO',
    condition: (stats) => stats.hasIntro && stats.hasProfileImage,
  ),

  // 메시지 관련
  TitleInfo(
    id: 'smalltalk_starter',
    name: '스몰토크 스타터',
    condition: (stats) => stats.messageCount >= 1,
  ),
  TitleInfo(
    id: 'smalltalk_master',
    name: '스몰토크의 귀재',
    condition: (stats) => stats.messageCount >= 20,
  ),
  TitleInfo(
    id: 'favorite_one',
    name: '한명이면 충분해',
    condition: (stats) => stats.friendsCount >= 1,
  ),
  TitleInfo(
    id: 'favorite_several',
    name: '여럿이 좋아',
    condition: (stats) => stats.friendsCount >= 5,
  ),
  TitleInfo(
    id: 'favorite_capybara',
    name: '카피바라',
    condition: (stats) => stats.friendsCount >= 10,
  ),

  // 투두리스트
  TitleInfo(
    id: 'todo_comfortable',
    name: '편안하게 사는',
    condition: (stats) => stats.todoCount >= 1,
  ),
  TitleInfo(
    id: 'todo_human',
    name: '사람처럼 사는',
    condition: (stats) => stats.todoCount >= 5,
  ),
  TitleInfo(
    id: 'todo_god',
    name: '갓생시작',
    condition: (stats) => stats.todoCount >= 10,
  ),
  TitleInfo(
    id: 'todo_killer',
    name: '투두리스트 학살자',
    condition: (stats) => stats.todoCount >= 15,
  ),

  // 투두리스트 N연속 달성
  TitleInfo(
    id: 'streak_1',
    name: '첫 걸음마',
    condition: (stats) => stats.consecutiveTodoSuccess >= 1,
  ),
  TitleInfo(
    id: 'streak_3',
    name: '뿌듯함',
    condition: (stats) => stats.consecutiveTodoSuccess >= 3,
  ),
  TitleInfo(
    id: 'streak_5',
    name: '노력의 결과',
    condition: (stats) => stats.consecutiveTodoSuccess >= 5,
  ),
  TitleInfo(
    id: 'streak_7',
    name: '이제는 습관',
    condition: (stats) => stats.consecutiveTodoSuccess >= 7,
  ),
];

/// ------------------------------
/// 함수명: addTitles
/// 목적: 획득한 타이틀을 SharedPreferences에 저장
/// 입력: List<TitleInfo> earnedTitles - 새로 획득한 타이틀 목록
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<void>
/// ------------------------------
Future<void> addTitles(
  List<TitleInfo> earnedTitles, {
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final unlocked = prefs.getStringList('unlocked_titles') ?? [];
  bool updated = false;

  for (var t in earnedTitles) {
    if (!unlocked.contains(t.name)) {
      unlocked.add(t.name);
      updated = true;
    }
  }
  if (updated) {
    await prefs.setStringList('unlocked_titles', unlocked);
    if (onUpdate != null) {
      onUpdate();
    }
  }
}

/// ------------------------------
/// 함수명: _getUnlockedTitles
/// 목적: SharedPreferences에 저장된 획득 타이틀 목록을 불러옴
/// 반환: Future<List<String>> - 획득한 타이틀 이름 목록
/// ------------------------------
Future<List<String>> _getUnlockedTitles() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('unlocked_titles') ?? [];
}

/// ------------------------------
/// 함수명: _setUnlockedTitles
/// 목적: 획득한 타이틀 목록을 SharedPreferences에 저장
/// 입력: List<String> titles - 저장할 타이틀 이름 목록
/// 반환: Future<void>
/// ------------------------------
Future<void> _setUnlockedTitles(List<String> titles) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('unlocked_titles', titles);
}

/// ------------------------------
/// 함수명: filterAndSaveTitles
/// 목적: 유저 상태를 기반으로 획득한 타이틀을 필터링하고 SharedPreferences에 저장
/// 입력: UserStats stats - 현재 유저 상태 정보
/// 입력: List<TitleInfo> titlesToCheck - 검사할 타이틀 목록
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> filterAndSaveTitles(
  UserStats stats,
  List<TitleInfo> titlesToCheck, {
  Function? onUpdate,
}) async {
  final earnedTitles = titlesToCheck.where((t) => t.condition(stats)).toList();

  final unlocked = await _getUnlockedTitles();
  bool updated = false;

  for (var t in earnedTitles) {
    if (!unlocked.contains(t.name)) {
      unlocked.add(t.name);
      updated = true;
    }
  }

  if (updated) {
    await _setUnlockedTitles(unlocked);
    if (onUpdate != null) onUpdate();
  }

  return earnedTitles;
}

/// ------------------------------
/// 함수명: checkEarnedTitles
/// 목적: 현재 유저 상태로 획득 가능한 모든 타이틀을 반환
/// 입력: UserStats stats - 현재 유저 상태 정보
/// 반환: List<TitleInfo> - 획득 가능한 타이틀 목록
/// ------------------------------
List<TitleInfo> checkEarnedTitles(UserStats stats) {
  return allTitles.where((title) => title.condition(stats)).toList();
}

/// ------------------------------
/// 함수명: handlePsychologyTestCompletion
/// 목적: 심리테스트 완료 후 유저 상태를 업데이트하고 타이틀 획득 여부를 검사
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handlePsychologyTestCompletion({
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // 저장된 검사 횟수 가져오기
  int count = prefs.getInt('psychology_test_count') ?? 0;
  count++; // 이번 완료 건 반영
  await prefs.setInt('psychology_test_count', count);

  // 현재 유저 상태 구성
  final stats = UserStats(psychologyTestCount: count);

  final psychologyTitles =
      allTitles
          .where(
            (t) =>
                t.id == 'spore_beginner' || t.id == 'spore_detailed_beginner',
          )
          .toList();

  return filterAndSaveTitles(stats, psychologyTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleNewUserTitle
/// 목적: 최초 회원가입 시 신규 유저 타이틀을 지급
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<void>
/// ------------------------------
Future<void> handleNewUserTitle({Function? onUpdate}) async {
  final stats = UserStats(psychologyTestCount: 0, isNewUser: true);

  final newUserTitles = allTitles.where((t) => t.id == 'spore_family').toList();

  await filterAndSaveTitles(stats, newUserTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleFriendCountChange
/// 목적: 친구 수 변경 시 호출하여 관련 타이틀 획득 여부를 검사
/// 입력: int newCount - 변경된 친구 수
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handleFriendCountChange(
  int newCount, {
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  int psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: psychologyCount,
    friendsCount: newCount,
  );

  final friendTitles =
      allTitles.where((t) => t.id.startsWith('friend_')).toList();

  return filterAndSaveTitles(stats, friendTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleProfileEditTitles
/// 목적: 프로필 편집(사진, 자기소개) 완료 후 관련 타이틀 획득 여부를 검사
/// 입력: bool hasIntro - 자기소개 존재 여부
/// 입력: bool hasProfileImage - 프로필 사진 존재 여부
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
Future<List<TitleInfo>> handleProfileEditTitles({
  required bool hasIntro,
  required bool hasProfileImage,
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  int psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: psychologyCount,
    hasIntro: hasIntro,
    hasProfileImage: hasProfileImage,
  );

  final profileTitles =
      allTitles
          .where(
            (t) =>
                t.id == 'intro_writer' ||
                t.id == 'photo_sharer' ||
                t.id == 'pro_pr',
          )
          .toList();

  return filterAndSaveTitles(stats, profileTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleMessageSentTitle
/// 목적: 메시지 전송 횟수에 따라 관련 타이틀 획득 여부를 검사
/// 입력: int messageCount - 총 보낸 메시지 횟수
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handleMessageSentTitle(
  int messageCount, {
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();
  int psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: psychologyCount,
    messageCount: messageCount,
  );

  final messageTitles =
      allTitles
          .where(
            (t) => t.id == 'smalltalk_starter' || t.id == 'smalltalk_master',
          )
          .toList();

  print('handleMessageSentTitle - 메시지 개수: $messageCount');
  print(
    'handleMessageSentTitle - 검사할 타이틀: ${messageTitles.map((t) => t.name).toList()}',
  );

  return filterAndSaveTitles(stats, messageTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleFavoriteFriendTitle
/// 목적: 즐겨찾기한 친구 수에 따라 관련 타이틀 획득 여부를 검사
/// 입력: int favoriteCount - 즐겨찾기한 친구 수
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handleFavoriteFriendTitle(
  int favoriteCount, {
  Function? onUpdate,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // 현재 저장된 심리테스트 횟수나 기타 필요한 상태 읽기
  int psychologyCount = prefs.getInt('psychology_test_count') ?? 0;

  final stats = UserStats(
    psychologyTestCount: psychologyCount,
    friendsCount: favoriteCount,
  );

  // 즐겨찾기 타이틀만 추출
  final favoriteTitles =
      allTitles
          .where(
            (t) =>
                t.id == 'favorite_one' ||
                t.id == 'favorite_several' ||
                t.id == 'favorite_capybara',
          )
          .toList();

  return filterAndSaveTitles(stats, favoriteTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: handleTodoCountTitle
/// 목적: 투두리스트 개수에 따라 관련 타이틀 획득 여부를 검사
/// 입력: int todoCount - 총 투두리스트 개수
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handleTodoCountTitle(
  int todoCount, {
  Function? onUpdate,
}) async {
  final stats = UserStats(
    todoCount: todoCount,
    messageCount: 0,
    psychologyTestCount: 0,
  );

  final todoTitles =
      allTitles
          .where(
            (t) =>
                t.id == 'todo_comfortable' ||
                t.id == 'todo_human' ||
                t.id == 'todo_god' ||
                t.id == 'todo_killer',
          )
          .toList();

  return await filterAndSaveTitles(stats, todoTitles, onUpdate: onUpdate);
}

/// ------------------------------
/// 함수명: calculateConsecutiveSuccessDays
/// 목적: 투두리스트 연속 성공 일수 계산
/// 입력: Map<DateTime, List<Event>> events - 이벤트 데이터 맵
/// 입력: DateTime fromDate - 계산을 시작할 날짜
/// 반환: int - 연속 성공 일수
/// ------------------------------
int calculateConsecutiveSuccessDays(
  Map<DateTime, List<Event>> events,
  DateTime fromDate,
) {
  int count = 0;
  DateTime date = fromDate;

  while (true) {
    final dayEvents = events[DateTime.utc(date.year, date.month, date.day)];
    if (dayEvents == null || dayEvents.isEmpty) break;

    // 해당 날짜에 모든 투두가 완료됐는지 체크
    final allCompleted = dayEvents.every((event) => event.isCompleted);
    if (!allCompleted) break;

    count++;
    date = date.subtract(const Duration(days: 1));
  }
  return count;
}

/// ------------------------------
/// 함수명: handleConsecutiveTodoSuccessTitle
/// 목적: 투두리스트 연속 성공 일수에 따라 관련 타이틀 획득 여부 검사
/// 입력: Map<DateTime, List<Event>> events - 이벤트 데이터 맵
/// 입력: DateTime referenceDate - 계산 기준 날짜
/// 입력: Function? onUpdate - 타이틀 목록 업데이트 시 호출할 콜백 함수 (선택 사항)
/// 반환: Future<List<TitleInfo>> - 새로 획득한 타이틀 목록
/// ------------------------------
Future<List<TitleInfo>> handleConsecutiveTodoSuccessTitle(
  Map<DateTime, List<Event>> events,
  DateTime referenceDate, {
  Function? onUpdate,
}) async {
  final consecutiveDays = calculateConsecutiveSuccessDays(
    events,
    referenceDate,
  );

  final stats = UserStats(
    psychologyTestCount: 0,
    consecutiveTodoSuccess: consecutiveDays,
  );

  final streakTitles =
      allTitles.where((t) => t.id.startsWith('streak_')).toList();

  return await filterAndSaveTitles(stats, streakTitles, onUpdate: onUpdate);
}
