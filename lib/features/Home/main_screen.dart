// lib/main_screen.dart

import 'package:flutter/material.dart';
import '../Friend/FriendScreen.dart';
import '../Timetable/TimetableScreen.dart';
import '../Calendar/HomeCalendar.dart';
import '../Timetable/course_model.dart';
import '../Timetable/TimetableList.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 시작 페이지를 '홈'으로 설정

  // 모든 시간표 데이터를 관리하는 맵
  final Map<String, List<Course>> _allTimetableCourses = {
    '2025-여름학기': [
      Course(
        title: '리눅스눅스',
        professor: '함부기',
        room: '제2호관-401',
        day: 0,
        startTime: 9,
        endTime: 11,
        color: const Color(0xFFCDDEE3),
      ),
      Course(
        title: '가부기와 햄 부기',
        professor: '미사에',
        room: '제5호관-409',
        day: 0,
        startTime: 13,
        endTime: 15,
        color: const Color(0xFF97B4C7),
      ),
    ],
    '2025-1학기': [
      Course(
        title: 'C언어',
        professor: '이성민',
        room: '공학관-301',
        day: 1,
        startTime: 10,
        endTime: 12,
        color: const Color(0xFFFFE0B2),
      ),
    ],
    '2024-2학기': [
      Course(
        title: '파이썬',
        professor: '홍길동',
        room: '제1공학관-101',
        day: 3,
        startTime: 9,
        endTime: 11,
        color: const Color(0xFFE1BEE7),
      ),
    ],
    '2024-겨울학기': [],
    '2024-여름학기': [],
    '2024-1학기': [],
  };

  late String _currentTimetableKey;

  @override
  void initState() {
    super.initState();
    // 초기 시간표 설정 (가장 최근 학기로)
    final sortedKeys =
        _allTimetableCourses.keys.toList()..sort((a, b) => b.compareTo(a));
    _currentTimetableKey = sortedKeys.first;
  }

  // 탭을 눌렀을 때 index를 변경하는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // onTimetableSelected 콜백 함수 정의
  void _onTimetableSelected(String newKey) {
    setState(() {
      _currentTimetableKey = newKey;
    });
  }

  // onCoursesUpdated 콜백 함수 정의
  void _onCoursesUpdated(List<Course> updatedCourses) {
    setState(() {
      _allTimetableCourses[_currentTimetableKey] = updatedCourses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 현재 선택된 시간표 데이터를 동적으로 가져옵니다.
    final currentCourses = _allTimetableCourses[_currentTimetableKey] ?? [];
    final parts = _currentTimetableKey.split('-');
    final currentTimetable = SemesterTimetable(
      year: parts[0],
      semester: parts[1],
      color:
          Colors.primaries[_allTimetableCourses.keys.toList().indexOf(
                _currentTimetableKey,
              ) %
              Colors.primaries.length],
    );

    // _widgetOptions를 빌드 메서드 내에서 동적으로 생성
    final List<Widget> widgetOptions = <Widget>[
      FriendScreen(),
      HomeCalendar(),
      TimetableScreen(
        timetable: currentTimetable,
        initialCourses: currentCourses,
        allTimetableCourses: _allTimetableCourses,
        onCoursesUpdated: _onCoursesUpdated, // 정의된 콜백 함수를 전달
        onTimetableSelected: _onTimetableSelected, // 정의된 콜백 함수를 전달
      ),
    ];

    return Scaffold(
      // 선택된 인덱스에 맞는 페이지를 보여줌
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: screenHeight * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Image.asset(
                    _selectedIndex == 0
                        ? 'assets/images/mainpage/friend_on.png'
                        : 'assets/images/mainpage/friend_off.png',
                    width: screenWidth * 0.058,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '친구',
                    style: TextStyle(
                      fontSize: screenWidth * 0.024,
                      color: const Color(0xFF515151),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Image.asset(
                    _selectedIndex == 1
                        ? 'assets/images/mainpage/home_on.png'
                        : 'assets/images/mainpage/home_off.png',
                    width: screenWidth * 0.058,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '홈',
                    style: TextStyle(
                      fontSize: screenWidth * 0.024,
                      color: const Color(0xFF515151),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Image.asset(
                    _selectedIndex == 2
                        ? 'assets/images/mainpage/timetable_on.png'
                        : 'assets/images/mainpage/timetable_off.png',
                    width: screenWidth * 0.058,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '시간표',
                    style: TextStyle(
                      fontSize: screenWidth * 0.024,
                      color: const Color(0xFF515151),
                      fontWeight: FontWeight.bold,
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
