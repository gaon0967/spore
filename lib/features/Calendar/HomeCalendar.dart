import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'Event.dart';
import '../Settings/SettingsScreen.dart';
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
  DateTime _focusedDay = getToday();
  DateTime _selectedDay = getToday();
  bool _isSettingsPressed = false;

  // 날짜별 일정 데이터를 저장할 Map
  final Map<DateTime, List<Event>> _events = {
    DateTime.utc(2025, 7, 31): [
      Event(
        title: '리눅스 과제 제출',
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 23, minute: 59),
        color: const Color(0xFFF4ECD2),
      ),
      Event(
        title: '학원 알바',
        startTime: TimeOfDay(hour: 10, minute: 0),
        endTime: TimeOfDay(hour: 22, minute: 0),
        color: const Color(0xFFCDDEE3),
        isCompleted: true,
      ),
    ],
  };

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // '+' 버튼을 눌렀을 때 새 다이얼로그를 띄우는 함수
  void _showAddEventDialog() async {
    final newEvent = await showDialog<Event>(
      context: context,
      builder: (BuildContext context) {
        return AddEventDialog(selectedDate: _selectedDay);
      },
    );

    if (newEvent != null) {
      setState(() {
        final day = DateTime.utc(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        );
        if (_events[day] != null) {
          _events[day]!.add(newEvent);
        } else {
          _events[day] = [newEvent];
        }
      });
    }
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
                                    MaterialPageRoute(builder: (context) => const NotificationPage()),
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
                                    _isSettingsPressed = false; // 터치가 취소되어도 false
                                  });
                                },
                                // --------------------------
                                child: Opacity(
                                  // _isSettingsPressed 상태에 따라 투명도를 조절 (눌렸을 때 50% 투명)
                                  opacity: _isSettingsPressed ? 0.5 : 1.0,
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
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  ); // 설정 화면으로 넘어감
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
                                    _isSettingsPressed = false; // 터치가 취소되어도 false
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
                                child: const Center(
                                  child: Text(
                                    '+',
                                    style: TextStyle(
                                      fontSize: 25,
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
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: eventsForSelectedDay.length,
                            itemBuilder: (context, index) {
                              final event = eventsForSelectedDay[index];
                              return Slidable(
                                key: Key(event.title + event.startTime.toString()), // 각 항목을 구분할 고유 키

                                // 오른쪽에서 왼쪽으로 밀었을 때 나타날 액션 창
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(), // 슬라이드 애니메이션 효과
                                  children: [
                                    // 삭제 액션 버튼
                                    CustomSlidableAction(
                                      onPressed: (context) {
                                        // 버튼을 눌렀을 때 실행될 삭제 로직
                                        setState(() {
                                          final day = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                                          _events[day]?.remove(event);

                                          //ScaffoldMessenger.of(context).showSnackBar(
                                            //SnackBar(content: Text('${event.title} 일정이 삭제되었습니다.')),
                                          //);
                                        });
                                      },
                                      backgroundColor: const Color(0xFFFFFF9),
                                      foregroundColor: const Color(0xFFDA6464),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center, // 아이콘과 텍스트를 세로 중앙 정렬
                                        children: [
                                          Image.asset(
                                            'assets/images/mainpage/delete.png', // 실제 이미지 경로
                                            width: 18, // 원하는 이미지 크기
                                            height: 18,
                                            //color: const Color.fromARGB(255, 121, 31, 31), // 이미지 색상 (단색 아이콘일 경우)
                                          ),
                                          const SizedBox(height: 4), // 이미지와 텍스트 사이 간격
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // 슬라이드 될 메인 컨텐츠 (기존의 일정 블록 UI)
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: screenWidth * 0.025,
                                  ),
                                  height: 75,
                                  decoration: BoxDecoration(
                                    color: event.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      event.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF4C4747),
                                        decoration: event.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${event.startTime.format(context)} ~ ${event.endTime.format(context)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF626262),
                                      ),
                                    ),
                                    trailing: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          event.isCompleted = !event.isCompleted;
                                        });
                                      },
                                      child: event.isCompleted
                                          ? const Text(
                                              '✓',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF6B6060),
                                              ),
                                            )
                                          : Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF6B6060,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
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

  const AddEventDialog({Key? key, required this.selectedDate})
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
    super.initState();
    _selectedColor = _colorOptions.first; // 첫 번째 색상을 기본값으로 설정

    final now = TimeOfDay.now();
    _startTime = now;
    // 종료 시간은 시작 시간보다 1시간 뒤로 설정 (사용자 편의성)
    // 23시일 경우 0시로 넘어가도록 % 24 연산 추가
    _endTime = now.replacing(hour: (now.hour + 1) % 24);
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final now = DateTime.now();
    DateTime tempPickedTime = DateTime( // 1. 선택한 시간을 임시로 저장할 변수
      now.year,
      now.month,
      now.day,
      initialTime?.hour ?? now.hour,
      initialTime?.minute ?? now.minute,
    );

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
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
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.12,
                ), // 이 값을 조절해 여백 크기를 변경하세요.
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
                                        color: const Color(0xFF504A4A),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
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
                // ▼▼▼▼▼ isSelected 값에 따라 색상 결정 ▼▼▼▼▼
                color: isSelected ? Colors.black : const Color(0xFFDADADA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
