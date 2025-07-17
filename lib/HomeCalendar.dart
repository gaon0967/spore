import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'TimetableScreen.dart'; // Make sure this file exists

// Utility function to return today's date at midnight
DateTime getToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day); // Set time to 00:00:00
}

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({Key? key}) : super(key: key);

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  int _selectedIndex = 1;
  DateTime _focusedDay = getToday();
  DateTime _selectedDay = getToday();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimetableScreen()),
      );
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF9),
      body: Column(
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
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: verticalPadding),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.09,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // [수정] 아이콘과 정렬을 위해 추가
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // [수정] Row를 RichText로 변경하여 '월'과 '년'을 한 줄에 표시
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
                          Icon(
                            Icons.notifications_none,
                            size: screenWidth * 0.065,
                            color: Colors.black54,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Container(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.settings,
                              size: screenWidth * 0.06,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: verticalPadding * 0.7),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
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
                          fontSize: screenWidth * 0.041,
                        ),
                      ),
                      Text(
                        'T',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.041,
                        ),
                      ),
                      Text(
                        'W',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.041,
                        ),
                      ),
                      Text(
                        'T',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.041,
                        ),
                      ),
                      Text(
                        'F',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.041,
                        ),
                      ),
                      Text(
                        'S',
                        style: TextStyle(
                          color: const Color(0xFF616192),
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.041,
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
                    locale: 'en_US',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    headerVisible: false,
                    daysOfWeekHeight: 0,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                        Color dateColor = Colors.black;
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
                        color: Color(0xFF555555),
                        fontSize: screenWidth * 0.035,
                      ),
                      // 선택된 날짜의 배경색 및 텍스트 스타일
                      selectedDecoration: BoxDecoration(
                        color: const Color(0xFFCA9E9E), // 원하는 색상
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                      ),
                      // 오늘 날짜의 배경색 및 텍스트 스타일 (파란색 원 제거)
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent, // 투명하게 설정하여 파란색 원 제거
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.black, // 오늘 날짜 텍스트 색상 (기본값으로)
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedDay',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            color: const Color(0xFF504A4A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          selectedEngWeekDay,
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            color: const Color(0xFF766E6E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '3 Tasks',
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            color: const Color(0xFF898989),
                          ),
                        ),
                        Spacer(),
                        Container(
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
                                fontSize: 28,
                                color: Colors.white,
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
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              bottom: screenWidth * 0.025,
                            ),
                            height: 75,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4ECD2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: const Text(
                                '리눅스 과제 제출',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4C4747),
                                ),
                              ),
                              subtitle: const Text(
                                '09:00 ~ 23:59',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF626262),
                                ),
                              ),
                              trailing: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF6B6060)),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 75,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCDDEE3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const ListTile(
                              title: Text(
                                '학원 알바',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF949494),
                                ),
                              ),
                              subtitle: Text(
                                '10:00 ~ 22:00',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF626262),
                                ),
                              ),
                              trailing: Text(
                                '✓',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B6060),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: screenHeight * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Icon(
                    Icons.person,
                    size: screenWidth * 0.058,
                    color: const Color(0xFF515151),
                  ),
                  SizedBox(height: 0),
                  Text(
                    '친구',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: const Color(0xFF515151),
                    ),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Icon(
                    Icons.home,
                    size: screenWidth * 0.058,
                    color: const Color(0xFF515151),
                  ),
                  SizedBox(height: 0),
                  Text(
                    '홈',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: const Color(0xFF515151),
                    ),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: screenWidth * 0.058,
                    color: const Color(0xFF515151),
                  ),
                  SizedBox(height: 0),
                  Text(
                    '시간표',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: const Color(0xFF515151),
                    ),
                  ),
                ],
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}