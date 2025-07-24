import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'Event.dart';
import '../Settings/settings_screen.dart';
import 'Notification.dart';
import 'package:flutter/cupertino.dart';

// UTC 자정 기준으로 날짜를 반환하는 함수
DateTime getToday() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day);
}

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({Key? key}) : super(key: key);

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  DateTime _focusedDay = getToday();
  DateTime _selectedDay = getToday();
  bool _isSettingsPressed = false;
  bool _isNotificationsPressed = false;
  Object? _pressedIndex;
  // 날짜별 일정 데이터를 저장할 Map
  final Map<DateTime, List<Event>> _events = {};

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // '+' 버튼을 눌렀을 때 새 다이얼로그를 띄우는 함수
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

    final day = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    // 수정 모드
    if (existingEvent != null && eventIndex != null) {
      setState(() {
        _getEventsForDay(day)[eventIndex] = result;
      });
    }
    // 추가 모드
    else {
      if (_events[day] == null) {
        _events[day] = [];
      }
      final eventsList = _getEventsForDay(day);
      final insertIndex = eventsList.length;

      // 1. 데이터 소스에 아이템을 추가하고 UI(카운터 등)를 업데이트
      setState(() {
        eventsList.add(result);
      });

      // 2. AnimatedList에 아이템 추가를 알림
      _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 180));
    }
  }

  // 삭제 버튼 로직 (AnimatedList에 맞게 수정)
  void _removeItem(int index) {
    final day = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    if (_events[day] == null || index >= _events[day]!.length) return;

    // 1. 데이터 소스에서 아이템을 제거하고, 그 아이템을 변수에 저장
    final eventToRemove = _events[day]!.removeAt(index);

    // 2. 다른 UI(예: 카운터)를 업데이트하기 위해 setState 호출
    setState(() {});

    // 3. AnimatedList에 아이템 제거 애니메이션 요청
    _listKey.currentState?.removeItem(
      index,
      (context, animation) {
        // 제거될 때 보여줄 위젯 (애니메이션 효과)
        return _buildRemovingAnimatedItem(eventToRemove, animation);
      },
      duration: const Duration(milliseconds: 180),
    );
  }

  Widget _buildEventContent(Event event, {int? index}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        if (index != null) {
          _showAddEventDialog(
            existingEvent: event,
            eventIndex: index,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.025),
        height: 75,
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            event.title,
            style: TextStyle(
              fontSize: screenWidth * 0.032,
              color: event.isCompleted ? const Color(0xFF626262) : const Color(0xFF4C4747),
              decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
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
            },
            child: event.isCompleted
                ? Text('✓', style: TextStyle(fontSize: screenWidth * 0.04, color: const Color(0xFF6B6060)))
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
    );
  }

  Widget _buildRemovingAnimatedItem(Event event, Animation<double> animation) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // SizeTransition이 애니메이션의 주체가 되도록 수정
    return SizeTransition(
      sizeFactor: animation,
      child: Row(
        children: [
          // 원래 Slidable의 비율(extentRatio: 0.7)에 맞춰 확장
          Expanded(
            flex: 7,
            child: _buildEventContent(event), // index를 null로 전달
          ),
          // 삭제 버튼 부분 (비율 0.3)
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.only(bottom: screenWidth * 0.025),
              height: 75, // 높이를 명시적으로 지정
              child: CustomSlidableAction(
                onPressed: (context) {}, // 애니메이션 중에는 동작 안 함
                backgroundColor: const Color(0xFFFFFEF9),
                foregroundColor: const Color(0xFFDA6464),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/mainpage/delete.png',
                      width: screenWidth * 0.043,
                      height: screenWidth * 0.043,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // AnimatedList의 아이템을 만드는 헬퍼 함수
Widget _buildAnimatedItem(Event event, int index, Animation<double> animation) {
  final screenWidth = MediaQuery.of(context).size.width;
  return SizeTransition(
    sizeFactor: animation,
    child: Listener(
      onPointerDown: (_) => setState(() => _pressedIndex = index),
      onPointerUp: (_) => setState(() => _pressedIndex = null),
      onPointerCancel: (_) => setState(() => _pressedIndex = null),
      // [ ✨ 그림자 제거 ✨ ]
      // Material 위젯으로 감싸고 type을 transparency로 설정하여 그림자 효과를 제거합니다.
      child: Material(
        type: MaterialType.transparency,
        child: Slidable(
          key: ValueKey(event),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.3,
            children: [
              CustomSlidableAction(
                onPressed: (context) => _removeItem(index),
                backgroundColor: const Color(0xFFFFFFF9),
                foregroundColor: const Color(0xFFDA6464),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/mainpage/delete.png',
                      width: screenWidth * 0.043,
                      height: screenWidth * 0.043,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.025),
            height: 75,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      // [ ✨ 네모 효과 제거 ✨ ]
                      // ListTile의 기본 터치 효과를 투명하게 만들어 제거합니다.
                      splashColor: Colors.transparent,
                      onTap: () {
                        _showAddEventDialog(
                            existingEvent: event, eventIndex: index);
                      },
                      title: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: event.isCompleted
                              ? const Color(0xFF626262)
                              : const Color(0xFF4C4747),
                          decoration: event.isCompleted
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
                          setState(() => event.isCompleted = !event.isCompleted);
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.all(8.0),
                          child: event.isCompleted
                              ? Text('✓',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: const Color(0xFF6B6060)))
                              : Container(
                                  width: screenWidth * 0.035,
                                  height: screenWidth * 0.035,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: const Color(0xFF6B6060)),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      color: _pressedIndex == index
                          ? Colors.black.withAlpha(38)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEventsMarker(DateTime day, List<Event> events) {
    // 상위 3개의 이벤트만 가져오거나, 3개 미만이면 있는 만큼만 가져옵니다.
    final eventsToShow = events.length > 3 ? events.sublist(0, 3) : events;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          eventsToShow.map((event) {
            return Container(
              width: 4.5, // 점의 너비
              height: 4.5, // 점의 높이
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
      // TimeOfDay(시, 분)를 분 단위로 변환하여 비교
      final aTotalMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bTotalMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aTotalMinutes.compareTo(bTotalMinutes);
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
                    SizedBox(height: verticalPadding),
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
                                onTap: () {
                                  print('알림 아이콘 클릭됨!');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const NotificationPage(),
                                    ),
                                  );
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
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const SettingsScreen(),
                                    ),
                                  );
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
                    SizedBox(height: 2),
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
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
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
                            Color dateColor = const Color(0xFF555555);
                            if (isSaturday) dateColor = const Color(0xFF616192);
                            if (isSunday) dateColor = const Color(0xFF8D2F2F);
                            return Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: dateColor,
                                  fontWeight: FontWeight.w400,
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
                      horizontal: screenWidth * 0.078,
                      vertical: verticalPadding * 0.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                              onTap: _showAddEventDialog, // <--- 함수 변경
                              child: Container(
                                width: screenWidth * 0.109,
                                height: screenWidth * 0.109,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF848CA6),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.055,
                                  ),
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
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: screenHeight * 0.032,
                          color: const Color(0xFFD9D9D9),
                          thickness: 0.8,
                        ),
                        Expanded(
                          // 여기가 AnimatedList로 변경된 부분
                          child: AnimatedList(
                            key: _listKey,
                            padding: EdgeInsets.zero,
                            initialItemCount: eventsForSelectedDay.length,
                            itemBuilder: (context, index, animation) {
                              if (index >= eventsForSelectedDay.length) return const SizedBox.shrink();
                              final event = eventsForSelectedDay[index];
                              return _buildAnimatedItem(event, index, animation);
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
      // TODO: 사용자에게 오류 메시지 표시 (예: SnackBar)
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
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF504A4A),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.011,
                      horizontal: screenWidth * 0.05,
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