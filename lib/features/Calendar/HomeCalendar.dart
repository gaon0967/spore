import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'event.dart';
import '../Settings/settings_screen.dart';
import 'Notification.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../Settings/TitleHandler.dart';
/* ├── HomeCalendar (StatefulWidget)
│   ├── State: _HomeCalendarState
│   │   ├── 날짜 상태 관리: _selectedDay, _focusedDay
│   │   ├── 일정 데이터: _events (Map<DateTime, List<Event>>)
│   │   ├── 일정 CRUD: 추가, 수정, 삭제
│   │   ├── UI 구성
│   │   │   ├── 상단: 월/년 텍스트 + 설정/알림 버튼
│   │   │   ├── TableCalendar (달력)
│   │   │   ├── 선택된 날짜 아래 일정 목록 (AnimatedList + Slidable)
│   └── 일정 추가 다이얼로그: AddEventDialog (Dialog 위젯)
*/

//========== getToday() : 시간은 제외하고, 오늘 날짜만 UTC 기준으로 반환해줌 ==========
DateTime getToday() {
  final now = DateTime.now(); // 현재 시간(날짜 + 시각)을 가져옴
  return DateTime.utc(now.year, now.month, now.day); // 현재 날짜에서 연도, 월, 일만 꺼냄
}

class HomeCalendar extends StatefulWidget {
  final void Function({int tabIndex, bool expandRequests}) onNavigateToFriends;
  // 사용자 정의 Stateful 위젯 클래스(화면 자동 갱신)
  const HomeCalendar({
    Key? key,
    required this.onNavigateToFriends,
  }) : super(key: key);

  @override
  State<HomeCalendar> createState() => _HomeCalendarState(); //실제 UI는 _HomeCalendarState 에서 정의됨
}

// =========== 상태를 관리하고 화면을 다시 그리는 _HomeCalendarState 클래스 ===========
class _HomeCalendarState extends State<HomeCalendar> {
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>(); //AnimatedList 위젯을 제어하기 위한 키
  DateTime _focusedDay = getToday(); //현재 화면에 보이는 날짜
  DateTime _selectedDay = getToday(); // 사용자가 직접 선택한 날짜
  bool _isSettingsPressed = false; // 설정 아이콘이 눌렸는지 여부 나타냄
  bool _isNotificationsPressed = false; // 알림 아이콘이 눌렸는지
  Object? _pressedIndex; // 사용자가 누른 리스트 아이템의 인덱스나 고유값을 담을 변수
  StreamSubscription? _plansSubscription;
  bool _isChangingDate = false;
  bool _isInitialLoad = true; // 앱이 처음 로딩 중인지 확인
  bool _isAddButtonPressed = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final Map<DateTime, List<Event>> _events =
      {}; //날짜(DateTime)를 키로, 해당 날짜에 있는 일정(Event) 리스트를 값으로 갖는 Map

  //============initState() :  캘린더 화면이 처음 열릴 때, Firestore 데이터베이스에 실시간 연결을 설정하고 자동 업데이트를 준비하는 역할 =================
  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _plansSubscription = _firestore //실시간 연결 설정 (구독)
          .collection('plans')
          .doc(_currentUser!.uid)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

            final Map<DateTime, List<Event>> loadedEvents = {}; // 데이터 변환 (파싱)

            if (snapshot.exists) {
              // 서버에 데이터가 있으면
              final data = snapshot.data();
              if (data != null && data['date'] != null) {
                final dateMap = data['date'] as Map<String, dynamic>;

                dateMap.forEach((dateString, dailyEventsMap) {
                  //date 정보 덩어리를 날짜별로 쪼갠다
                  final year = int.parse(dateString.substring(0, 4));
                  final month = int.parse(dateString.substring(4, 6));
                  final day = int.parse(dateString.substring(6, 8));
                  final dateTime = DateTime.utc(year, month, day);

                  final events =
                      (dailyEventsMap as Map<String, dynamic>).values.map((
                        eventData,
                      ) {
                        // 각 날짜에 있는 일정들을 Event 객체로 변환
                        final startTimeParts =
                            (eventData['startTime'] as String).split(':');
                        final endTimeParts = (eventData['endTime'] as String)
                            .split(':');
                        return Event(
                          id: eventData['id'],
                          title: eventData['title'],
                          color: Color(eventData['color']),
                          isCompleted: eventData['isDone'],
                          startTime: TimeOfDay(
                            hour: int.parse(startTimeParts[0]),
                            minute: int.parse(startTimeParts[1]),
                          ),
                          endTime: TimeOfDay(
                            hour: int.parse(endTimeParts[0]),
                            minute: int.parse(endTimeParts[1]),
                          ),
                        );
                      }).toList();

                  events.sort((a, b) {
                  // 1순위: 시작 시간 (오름차순)
                  final aStart = a.startTime.hour * 60 + a.startTime.minute;
                  final bStart = b.startTime.hour * 60 + b.startTime.minute;
                  int startCompare = aStart.compareTo(bStart);
                  if (startCompare != 0) {
                      return startCompare;
                  }

                  // 2순위: 종료 시간 (오름차순)
                  final aEnd = a.endTime.hour * 60 + a.endTime.minute;
                  final bEnd = b.endTime.hour * 60 + b.endTime.minute;
                  return aEnd.compareTo(bEnd);
                });
                  loadedEvents[dateTime] =
                      events; //깔끔하게 변환된 Event 객체들을 날짜별로 묶어 loadedEvents 라는 최종 결과물에 차곡차곡 정리
                });
              }
            }

            setState(() {
              // 화면 갱신 (UI 업데이트)
              _events.clear();
              _events.addAll(loadedEvents);
              if (_isInitialLoad) {
                _isInitialLoad = false;
              }
            });
          });
    }
  }

  // ============== dispose() :  화면이 없어질 때 데이터 수신을 중단하여 메모리 누수를 방지 ========================
  @override
  void dispose() {
    _plansSubscription?.cancel();
    super.dispose();
  }

  //================= 새로운 일정을 데이터베이스에 추가하거나 기존 일정을 수정(업데이트)하는 역할 ==========================================
  void _addOrUpdateEvent(Event event, {bool isUpdating = false}) {
    if (_currentUser == null) return;

    // 새 이벤트인 경우 고유 ID 생성
    if (!isUpdating && event.id == null) {
      event.id = _firestore.collection('plans').doc().id;
    }

    final dayKey = DateFormat('yyyyMMdd').format(_selectedDay);
    final docRef = _firestore.collection('plans').doc(_currentUser!.uid);

    final eventMap = {
      'id': event.id,
      'title': event.title,
      'color': event.color.value,
      'isDone': event.isCompleted,
      'startTime':
          '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
    };

    // 점(.) 표기법을 사용하여 특정 날짜의 맵에 일정을 추가하거나 덮어쓰기
    docRef.set({
      // // 최종적으로 변환된 eventMap 데이터를 Firestore에 저장
      'uid': _currentUser!.uid, // 사용자 ID도 함께 저장
      'date': {
        dayKey: {event.id: eventMap},
      },
    }, SetOptions(merge: true)); // merge:true는 다른 날짜 데이터를 보존
  }

  //=====================일정 삭제 firebase 관리용================================
  void _deleteEvent(Event event) {
    if (_currentUser == null || event.id == null) return;

    final dayKey = DateFormat('yyyyMMdd').format(_selectedDay);
    final docRef = _firestore.collection('plans').doc(_currentUser!.uid);

    // FieldValue.delete()를 사용하여 맵에서 해당 키-값 쌍을 제거
    docRef.update({'date.$dayKey.${event.id}': FieldValue.delete()});
  }

  // ==================== _getEventsForDay() ===============================
  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  } //전달받은 day에 해당하는 날짜에 어떤 일정이 있는지 _events 맵에서 찾아서 리스트로 반환

  // ===== _showAddEventDialog() : '+' 버튼을 눌렀을 때 새 다이얼로그를 띄우는 함수 ====
  void _showAddEventDialog({Event? existingEvent, int? eventIndex}) async {
    final result = await showDialog<Event>(
      context: context,
      builder: (BuildContext context) {
        return AddEventDialog(
          selectedDate: _selectedDay,
          eventToEdit: existingEvent,
        );
      },
    );

    if (result == null) return;

    final day = DateTime.utc(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final eventsForDay = _getEventsForDay(day);

    if (existingEvent != null && eventIndex != null) {
      setState(() {
        result.id = existingEvent.id;
        eventsForDay[eventIndex] = result;
      });
      _addOrUpdateEvent(result, isUpdating: true);
    } else {
      _addOrUpdateEvent(result); // Firestore에 먼저 추가

      final newEventStartTimeMinutes =
          result.startTime.hour * 60 + result.startTime.minute;
      final newEventEndTimeMinutes =
          result.endTime.hour * 60 + result.endTime.minute;

      int lastIndex = eventsForDay.lastIndexWhere((event) {
        final existingEventStartTimeMinutes =
            event.startTime.hour * 60 + event.startTime.minute;
        final existingEventEndTimeMinutes =
            event.endTime.hour * 60 + event.endTime.minute;

        // 시작 시간이 같을 경우, 끝나는 시간이 더 빠른 이벤트를 먼저 정렬
        if (existingEventStartTimeMinutes == newEventStartTimeMinutes) {
          return existingEventEndTimeMinutes <= newEventEndTimeMinutes;
        }
        // 시작 시간이 다를 경우, 시작 시간으로 정렬
        return existingEventStartTimeMinutes <= newEventStartTimeMinutes;
      });

      final insertIndex = lastIndex == -1 ? 0 : lastIndex + 1;

      setState(() {
        if (_events[day] == null) _events[day] = [];
        eventsForDay.insert(insertIndex, result);
      });

      // 투두리스트 개수 타이틀 지급
      final currentTodoCount = _getEventsForDay(day).length;
      handleTodoCountTitle(currentTodoCount, onUpdate: () {
        setState(() {}); // UI 갱신
      });

      _listKey.currentState?.insertItem(
        insertIndex,
        duration: const Duration(milliseconds: 180),
      );
    }
  }

  // 삭제 버튼 로직
  void _removeItem(int index) {
    final day = DateTime.utc(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    if (_events[day] == null || index >= _events[day]!.length) return;

    // 1. 로컬 리스트에서 제거할 아이템을 먼저 가져옴
    final eventToRemove = _getEventsForDay(day).removeAt(index);

    // 2. 애니메이션 실행
    _listKey.currentState?.removeItem(index, (context, animation) {
      return _buildRemovingAnimatedItem(eventToRemove, animation);
    }, duration: const Duration(milliseconds: 180));

    // 3. UI 상태 업데이트 (카운터 등)
    setState(() {});

    // 4. Firestore에서 데이터 삭제
    _deleteEvent(eventToRemove);

    // 투두리스트 개수 타이틀 지급
    final currentTodoCount = _getEventsForDay(day).length;
    handleTodoCountTitle(currentTodoCount, onUpdate: () {
      setState(() {}); // UI 갱신
    });

  }

  Widget _buildEventContent(Event event, {int? index}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        if (index != null) {
          _showAddEventDialog(existingEvent: event, eventIndex: index);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.025),
        height: screenWidth * 0.19,
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(12),
        ),
        // ListTile을 Center 위젯으로 감싸서 세로 중앙 정렬을 해줍니다.
        child: Center(
          child: ListTile(
            title: Text(
              event.title,
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color:
                    event.isCompleted
                        ? const Color(0xFF626262)
                        : const Color(0xFF4C4747),
                decoration:
                    event.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
              ),
            ),
            subtitle: Text(
              '${event.startTime.format(context)} ~ ${event.endTime.format(context)}',
              style: TextStyle(
                fontSize: screenWidth * 0.024,
                color: const Color(0xFF626262),
              ),
            ),
            trailing: GestureDetector(
              onTap: () {
                setState(() {
                  event.isCompleted = !event.isCompleted;
                });
                // isDone 상태 변경 시 Firestore에도 업데이트
                _addOrUpdateEvent(event, isUpdating: true);

                // 투두리스트 연속 성공 일수 기반 타이틀 갱신
                handleConsecutiveTodoSuccessTitle(_events, _selectedDay, onUpdate: () {
                  setState(() {});
                });
              },
              child:
                  event.isCompleted
                      ? Text(
                        '✓',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: const Color(0xFF6B6060),
                        ),
                      )
                      : Container(
                        width: screenWidth * 0.035,
                        height: screenWidth * 0.035,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF6B6060)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Route _createSettingsSlidingRoute() {
    return PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) => const SettingsScreen(),
      transitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0); // 오른쪽에서 시작
        var end = Offset.zero; // 중앙으로 이동
        var curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Route _createSlidingRoute(
    void Function({int tabIndex, bool expandRequests}) onNavigateToFriendsCallback,
  ) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => NotificationPage(
        // 전달받은 콜백 함수를 NotificationPage에 넘겨줍니다.
        onNavigateToFriends: onNavigateToFriendsCallback,
      ),
      transitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Widget _buildRemovingAnimatedItem(Event event, Animation<double> animation) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        color: const Color(0xFFFFFEF9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: screenWidth * 0.3,
                // Column을 Row로 변경
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // 정렬을 start(왼쪽)로 변경
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: screenWidth * 0.085), // 왼쪽 여백 추가
                    Padding(
                      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                      child: Image.asset(
                        'assets/images/mainpage/delete.png',
                        width: screenWidth * 0.044,
                        height: screenWidth * 0.044,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-screenWidth * 0.3, 0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: _buildEventContent(event, index: null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AnimatedList의 아이템을 만드는 헬퍼 함수
  Widget _buildAnimatedItem(
    Event event,
    int index,
    Animation<double> animation,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizeTransition(
      sizeFactor: animation,
      child: Slidable(
        key: ValueKey(event.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          children: [
            CustomSlidableAction(
              onPressed: (context) => _removeItem(index),
              backgroundColor: const Color(0xFFFFFEF9),
              foregroundColor: const Color(0xFFDA6464),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: screenWidth * 0.03),
                  Padding(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                    child: Image.asset(
                      'assets/images/mainpage/delete.png',
                      width: screenWidth * 0.044,
                      height: screenWidth * 0.044,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Listener(
            onPointerDown: (_) => setState(() => _pressedIndex = index),
            onPointerUp: (_) => setState(() => _pressedIndex = null),
            onPointerCancel: (_) => setState(() => _pressedIndex = null),
            child: Stack(
              children: [
                // 1. 원래의 일정 내용
                _buildEventContent(event, index: index),

                // 2. 터치 효과를 위한 그림자 오버레이
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: screenWidth * 0.19,
                    margin: EdgeInsets.only(bottom: screenWidth * 0.025),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          _pressedIndex == index
                              ? Colors.black.withAlpha(32)
                              : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime day, List<Event> events) {
    // 상위 3개의 이벤트만 가져오거나, 3개 미만이면 있는 만큼만 가져옵니다.
    final eventsToShow = events.length > 3 ? events.sublist(0, 3) : events;
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          eventsToShow.map((event) {
            return Container(
              width: screenWidth * 0.0105, // 점의 너비
              height: screenWidth * 0.0105, // 점의 높이
              margin: const EdgeInsets.symmetric(horizontal: 1.0), // 점 사이의 간격
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: event.color, // 각 일정의 색상으로 점 색상 지정
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.03;

    final month = _focusedDay.month;
    final year = _focusedDay.year;

    final selectedDate = _selectedDay;
    final selectedDay = selectedDate.day;
    final selectedEngWeekDay =
        DateFormat('EEE', 'en').format(selectedDate).toUpperCase();

    final eventsForSelectedDay = _getEventsForDay(_selectedDay);
    eventsForSelectedDay.sort((a, b) {
      // 1. 시작 시간을 분으로 변환하여 비교
      final aStartMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bStartMinutes = b.startTime.hour * 60 + b.startTime.minute;

      int compare = aStartMinutes.compareTo(bStartMinutes);

      // 2. 시작 시간이 같다면, 종료 시간을 기준으로 재정렬
      if (compare == 0) {
        final aEndMinutes = a.endTime.hour * 60 + a.endTime.minute;
        final bEndMinutes = b.endTime.hour * 60 + b.endTime.minute;
        return aEndMinutes.compareTo(bEndMinutes); // 종료 시간 오름차순
      }

      return compare; // 시작 시간 오름차순
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFF9),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      offset: const Offset(0, 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: verticalPadding + screenHeight * 0.025),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.07,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$month월 ',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.065,
                                    color: const Color(0xFF504A4A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '$year년',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: const Color(0xFF868686),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  // 1. async 키워드 추가
                                  print('알림 아이콘 클릭됨!');

                                  // 2. Navigator.push가 결과를 반환할 때까지 기다림 (await)
                                  final selectedDateFromNoti = await Navigator.push(
                                    context,
                                    _createSlidingRoute(widget.onNavigateToFriends),// NotificationPage를 여는 함수
                                  );

                                  // 3. 만약 NotificationPage에서 날짜(DateTime)를 반환했다면
                                  if (selectedDateFromNoti is DateTime) {
                                    // 4. 달력의 선택된 날짜와 포커스를 그 날짜로 변경
                                    setState(() {
                                      _selectedDay = selectedDateFromNoti;
                                      _focusedDay = selectedDateFromNoti;
                                    });
                                  }
                                },
                                // --- 투명도 효과를 위한 부분 ---
                                onTapDown: (details) {
                                  setState(() {
                                    _isNotificationsPressed =
                                        true; // 누르기 시작하면 true
                                  });
                                },
                                onTapUp: (details) {
                                  setState(() {
                                    _isNotificationsPressed =
                                        false; // 손가락을 떼면 false
                                  });
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _isNotificationsPressed =
                                        false; // 터치가 취소되어도 false
                                  });
                                },
                                // --------------------------
                                child: Opacity(
                                  // _isSettingsPressed 상태에 따라 투명도를 조절 (눌렸을 때 50% 투명)
                                  opacity: _isNotificationsPressed ? 0.5 : 1.0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.5),
                                    child: Image.asset(
                                      'assets/images/mainpage/notifications.png',
                                      width: screenWidth * 0.052,
                                      height: screenWidth * 0.052,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              GestureDetector(
                                onTap: () {
                                  print('설정 아이콘 클릭됨!');
                                  Navigator.push(
                                      context, _createSettingsSlidingRoute());
                                },
                                // --- 투명도 효과를 위한 부분 ---
                                onTapDown: (details) {
                                  setState(() {
                                    _isSettingsPressed = true; // 누르기 시작하면 true
                                  });
                                },
                                onTapUp: (details) {
                                  setState(() {
                                    _isSettingsPressed = false; // 손가락을 떼면 false
                                  });
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _isSettingsPressed =
                                        false; // 터치가 취소되어도 false
                                  });
                                },
                                // --------------------------
                                child: Opacity(
                                  // _isSettingsPressed 상태에 따라 투명도를 조절 (눌렸을 때 50% 투명)
                                  opacity: _isSettingsPressed ? 0.5 : 1.0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.1),
                                    child: Image.asset(
                                      'assets/images/mainpage/setting.png',
                                      width: screenWidth * 0.085,
                                      height: screenWidth * 0.085,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalPadding * 0.7),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'S',
                            style: TextStyle(
                              color: const Color(0xFF8D2F2F),
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.041,
                            ),
                          ),
                          Text(
                            'M',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          Text(
                            'T',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          Text(
                            'W',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          Text(
                            'T',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          Text(
                            'F',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          Text(
                            'S',
                            style: TextStyle(
                              color: const Color(0xFF616192),
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.048,
                      ),
                      child: TableCalendar(
                        eventLoader: _getEventsForDay,
                        locale: 'ko_KR',
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        headerVisible: false,
                        daysOfWeekHeight: 0,
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          if (isSameDay(_selectedDay, selectedDay)) return;

                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _isChangingDate = true; // 날짜가 바뀌었음을 알림
                          });

                          //  한 프레임 뒤에 _isChangingDate를 false로 되돌려 리스트를 다시 표시
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _isChangingDate = false;
                            });
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            final eventList = events.cast<Event>().toList();
                            if (eventList.isNotEmpty) {
                              return Align(
                                alignment: Alignment(
                                  0.0,
                                  0.8,
                                ), // 가로는 중앙, 세로는 중앙에서 약간 아래
                                child: _buildEventsMarker(day, eventList),
                              );
                            }
                            return null;
                          },
                          defaultBuilder: (context, day, focusedDay) {
                            final isSaturday = day.weekday == DateTime.saturday;
                            final isSunday = day.weekday == DateTime.sunday;
                            Color dateColor = const Color.fromARGB(
                              255,
                              119,
                              119,
                              119,
                            );
                            if (isSaturday) dateColor = const Color(0xFF616192);
                            if (isSunday) dateColor = const Color(0xFF8D2F2F);
                            return Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: dateColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            );
                          },
                        ),
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.all(12.5),
                          weekendTextStyle: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.035,
                          ),
                          outsideTextStyle: const TextStyle(
                            color: Color(0xFFC1C1C1),
                          ),
                          defaultTextStyle: TextStyle(
                            color: const Color(0xFF555555),
                            fontSize: screenWidth * 0.035,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFFCA9E9E),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                          ),
                          todayDecoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: const Color(0xFF555555),
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        calendarFormat: CalendarFormat.month,
                      ),
                    ),
                    SizedBox(height: verticalPadding),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: verticalPadding * 0.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          // 제목 부분에는 여백을 유지하기 위해 Padding을 추가
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$selectedDay',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.055,
                                      color: const Color(0xFF4C4747),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    selectedEngWeekDay,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
                                      color: const Color(0xFF4C4747),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Text(
                                '${eventsForSelectedDay.length}개의 할 일',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  color: const Color(0xFF898989),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _showAddEventDialog,
                                onTapDown: (_) => setState(() => _isAddButtonPressed = true),
                                onTapUp: (_) => setState(() => _isAddButtonPressed = false),
                                onTapCancel: () => setState(() => _isAddButtonPressed = false),
                                child: Stack( // 버튼과 효과를 겹치기 위해 Stack 사용
                                  alignment: Alignment.center,
                                  children: [
                                    // 1. 원래 버튼 모양
                                    Container(
                                      width: screenWidth * 0.109,
                                      height: screenWidth * 0.109,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF848CA6),
                                        borderRadius: BorderRadius.circular(screenWidth * 0.055),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.06,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 2. 터치 효과를 위한 오버레이
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: screenWidth * 0.109,
                                      height: screenWidth * 0.109,
                                      decoration: BoxDecoration(
                                        // _isAddButtonPressed 상태에 따라 색상이 나타나거나 사라짐
                                        color: _isAddButtonPressed
                                            ? Colors.black.withOpacity(0.24) // 눌렸을 때 덧씌워질 어두운 색
                                            : Colors.transparent, // 평소에는 투명
                                        borderRadius: BorderRadius.circular(screenWidth * 0.055),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: screenWidth * 0.04,
                          color: const Color(0xFFD9D9D9),
                          thickness: 0.8,
                        ),
                        SizedBox(height: screenWidth * 0.025),
                        Expanded(
                          child:
                              (_isInitialLoad)
                                  ? const Center(
                                    child: CupertinoActivityIndicator(),
                                  ) // 초기 로딩 중일 때 로딩 아이콘 표시
                                  : (_isChangingDate)
                                  ? Container() // 날짜 변경 중일 때 빈 화면 표시
                                  : AnimatedList(
                                    key: _listKey,
                                    padding: EdgeInsets.zero,
                                    initialItemCount:
                                        eventsForSelectedDay.length,
                                    itemBuilder: (context, index, animation) {
                                      if (index >=
                                          eventsForSelectedDay.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final event = eventsForSelectedDay[index];
                                      return _buildAnimatedItem(
                                        event,
                                        index,
                                        animation,
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 새로운 디자인의 일정 추가 다이얼로그 위젯 ---
class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Event? eventToEdit;
  const AddEventDialog({Key? key, required this.selectedDate, this.eventToEdit})
    : super(key: key);

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isStartTimeSelected = false;
  bool _isEndTimeSelected = false;
  bool _isTimeValid = true; //시간이 유효한지 저장하는 상태 변수

  // CSS 기반 색상 목록
  final List<Color> _colorOptions = [
    const Color(0xFF95A797),
    const Color(0xFFDDD2DA),
    const Color(0xFFF4ECD2),
    const Color(0xFF7887AD),
    const Color(0xFFE6E6E6),
    const Color(0xFFB3A6A6),
    const Color(0xFFCA9E9E),
    const Color(0xFFCDDEE3),
  ];
  late Color _selectedColor;

  @override
  void initState() {
    if (widget.eventToEdit != null) {
      // 수정 모드일 때: 전달받은 데이터로 초기값 설정
      _titleController.text = widget.eventToEdit!.title;
      _startTime = widget.eventToEdit!.startTime;
      _endTime = widget.eventToEdit!.endTime;
      _selectedColor = widget.eventToEdit!.color;
      _isStartTimeSelected = true; // 이미 시간이 설정되었으므로 true
      _isEndTimeSelected = true;
    } else {
      // 추가 모드일 때: 기존 로직
      _selectedColor = _colorOptions.first;
      final now = TimeOfDay.now();
      _startTime = now;
      _endTime = now.replacing(hour: (now.hour + 1) % 24);
    }
    _validateTimes();
  }

  void _validateTimes() {
    if (_startTime == null || _endTime == null) {
      setState(() => _isTimeValid = true);
      return;
    }
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    // 종료 시간이 시작 시간보다 크거나 같으면 유효
    setState(() {
      _isTimeValid = endMinutes >= startMinutes;
    });
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final now = DateTime.now();
    DateTime tempPickedTime = DateTime(
      // 1. 선택한 시간을 임시로 저장할 변수
      now.year,
      now.month,
      now.day,
      initialTime?.hour ?? now.hour,
      initialTime?.minute ?? now.minute,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: screenWidth * 0.4,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () {
                      // 3. '완료' 버튼을 누를 때만 setState로 최종 반영
                      setState(() {
                        final newTime = TimeOfDay.fromDateTime(tempPickedTime);
                        if (isStartTime) {
                          _startTime = newTime;
                          _isStartTimeSelected = true;
                        } else {
                          _endTime = newTime;
                          _isEndTimeSelected = true;
                        }
                        _validateTimes();
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  initialDateTime: tempPickedTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    // 2. 휠을 돌릴 때는 임시 변수 값만 변경 (setState 없음!)
                    tempPickedTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty ||
        _startTime == null ||
        _endTime == null) {
      return;
    }
    final newEvent = Event(
      title: _titleController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      color: _selectedColor,
    );
    Navigator.of(context).pop(newEvent);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 화면 비율에 따른 값 조절
    final dialogHorizontalPadding = screenWidth * 0.15; // 화면 너비의 10%
    final dialogVerticalPadding = screenHeight * 0.1; // 화면 높이의 3%
    final contentPadding = screenWidth * 0.05; // 내부 컨텐츠 패딩
    final spacingHeight = screenHeight * 0.006; // 위젯 간 세로 간격
    final titleFontSize = screenWidth * 0.036;
    final hintFontSize = screenWidth * 0.055;
    final timeLabelFontSize = screenWidth * 0.036;
    final timeValueFontSize = screenWidth * 0.036;
    final colorOptionSize = screenWidth * 0.045; // 색상 선택 원 크기
    final saveButtonTextSize = screenWidth * 0.04;

    return Dialog(
      backgroundColor: Colors.transparent, // Dialog 자체의 배경은 투명하게
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogHorizontalPadding,
        vertical: dialogVerticalPadding,
      ),
      child: Container(
        padding: EdgeInsets.all(contentPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF9),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: SingleChildScrollView(
          // 내용이 길어질 경우 스크롤 가능하게
          child: Column(
            mainAxisSize: MainAxisSize.min, // 컬럼의 크기를 내용에 맞게 최소화
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat(
                  'M월 d일 (EEE)',
                  'en',
                ).format(widget.selectedDate).toUpperCase(),
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF504A4A),
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: spacingHeight * 2), // 간격 조절
              TextField(
                controller: _titleController,
                textAlign: TextAlign.left,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: hintFontSize,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: '할 일 입력',
                  hintStyle: const TextStyle(color: Color(0xFFBEBEBE)),
                  border: InputBorder.none,
                  // 내용이 길어질 경우를 대비해 텍스트필드 높이 조절
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.01,
                  ),
                ),
              ),
              SizedBox(height: spacingHeight),
              _buildTimeRow(
                '시작 시간',
                _startTime,
                () => _pickTime(context, isStartTime: true),
                timeLabelFontSize,
                timeValueFontSize,
                _isStartTimeSelected,
              ),
              SizedBox(height: spacingHeight * 0.5), // 시간 줄 사이 간격
              _buildTimeRow(
                '종료 시간',
                _endTime,
                () => _pickTime(context, isStartTime: false),
                timeLabelFontSize,
                timeValueFontSize,
                _isEndTimeSelected,
              ),
              SizedBox(height: spacingHeight * 3.2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: screenWidth * 0.03, // 색상 원 간격
                  crossAxisSpacing: screenWidth * 0.03, // 색상 원 간격
                  physics:
                      const NeverScrollableScrollPhysics(), // GridView가 부모의 스크롤을 방해하지 않도록
                  children:
                      _colorOptions.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: colorOptionSize, // 반응형 크기 적용
                            height: colorOptionSize, // 반응형 크기 적용
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border:
                                  _selectedColor == color
                                      ? Border.all(
                                        color: Color.fromARGB(
                                          150,
                                          109,
                                          101,
                                          101,
                                        ), // 알파 값 150으로 변경
                                        width: screenWidth * 0.005,
                                      )
                                      : null, // 테두리 두께도 반응형
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: spacingHeight * 3.2),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isTimeValid ? _saveEvent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF504A4A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.011,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    TimeOfDay? time,
    VoidCallback onPressed,
    double labelSize,
    double valueSize,
    bool isSelected, // <--- 시간이 선택되었는지 여부를 받는 파라미터 추가
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize * 0.94,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF000000),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(
              time?.format(context) ?? '00:00',
              style: TextStyle(
                fontSize: valueSize * 0.94,
                color: isSelected ? Colors.black : const Color(0xFFDADADA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
