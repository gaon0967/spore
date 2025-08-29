// lib/main_screen.dart

import 'package:flutter/material.dart';
import '../Friend/FriendScreen.dart';
import '../Timetable/TimetableScreen.dart';
import '../Calendar/HomeCalendar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 시작 페이지를 '홈'으로 설정
  // FriendScreen의 상태를 제어할 변수
  int _friendScreenTabIndex = 0;
  bool _expandFriendRequests = false;

  late List<Widget> _widgetOptions;
  Key? _friendScreenKey;

  @override
  void initState() {
    super.initState();
    _buildWidgetOptions(); // initState에서 위젯 리스트 생성
  }

  // 위젯 리스트를 상태에 따라 동적으로 생성하는 함수
  void _buildWidgetOptions() {
    _widgetOptions = <Widget>[
      FriendScreen(
        key: _friendScreenKey,
        initialTabIndex: _friendScreenTabIndex,
        expandRequestsSection: _expandFriendRequests,
        onNavigateToFriends: _navigateToFriendsTab,
      ),
      HomeCalendar(
        // HomeCalendar에 콜백 함수 전달
        onNavigateToFriends: _navigateToFriendsTab,
      ),
      TimetableScreen(),
    ];
  }

  // 외부 신호를 받아 탭과 FriendScreen 상태를 변경하는 함수
  void _navigateToFriendsTab({int tabIndex = 0, bool expandRequests = false}) {
    setState(() {
      _selectedIndex = 0; // BottomNavigationBar의 '친구' 탭(index 0)으로 이동
      _friendScreenTabIndex = tabIndex;
      _expandFriendRequests = expandRequests;
      if (tabIndex == 1 && expandRequests == true) {
        // UniqueKey()는 매번 다른 값을 가지는 특별한 Key입니다.
        _friendScreenKey = UniqueKey();
      } else {
        // 일반적인 탭 전환 시에는 Key를 null로 설정하여 상태를 유지합니다.
        _friendScreenKey = null;
      }
      _buildWidgetOptions(); // 변경된 상태로 위젯 리스트를 다시 빌드
    });
  }
  // 탭을 눌렀을 때 index를 변경하는 함수
  void _onItemTapped(int index) {
    if (index == 0) {
      // 사용자가 직접 탭을 누를 땐, FriendScreen 상태를 초기화
      _navigateToFriendsTab(); 
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required String label,
    required String activeIconPath,
    required String inactiveIconPath,
    required BuildContext context, // context를 전달받도록 추가
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: '', // label은 비워둡니다.
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // 애니메이션 효과
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // isSelected 상태에 따라 배경색과 모양 결정
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(30), // 타원 모양
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isSelected ? activeIconPath : inactiveIconPath,
              width: screenWidth * 0.058,
              height: screenWidth * 0.058, // 높이도 지정하여 아이콘 크기 고정
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.024,
                color: const Color(0xFF515151),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // 선택된 인덱스에 맞는 페이지를 보여줌
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: screenHeight * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed, // 아이콘과 텍스트가 함께 보이도록 타입 변경
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false, // label 숨기기
          showUnselectedLabels: false,
          items: [
            // 0번 탭: 친구
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Image.asset(
                    _selectedIndex == 0
                     ? 'assets/images/mainpage/friend_on.png'  // 선택됐을 때
                     : 'assets/images/mainpage/friend_off.png', // 선택 안됐을 때
                   width: screenWidth * 0.058,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '친구',
                    style: TextStyle(
                      fontSize: screenWidth * 0.024,
                      color:const Color(0xFF515151),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              label: '',
              ),
            // 1번 탭: 홈
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
            // 2번 탭: 시간표
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Image.asset(
                    _selectedIndex == 2
                      ? 'assets/images/mainpage/timetable_on.png'
                      : 'assets/images/mainpage/timetable_off.png',
                    width: screenWidth * 0.058,
                  ),
                  SizedBox(height: screenWidth*0.0095),
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