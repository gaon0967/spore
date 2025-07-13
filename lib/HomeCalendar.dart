import 'package:flutter/material.dart';

int _selectedIndex = 0; // 현재 선택된 탭 인덱스

class HomeCalendar extends StatelessWidget {
  const HomeCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(title: const Text("메인 화면")),
      body: const Center(
        child: Text("로그인 성공!", style: TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/images/mainpage/friend.png')),
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/images/mainpage/home.png')),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Image(
              image: AssetImage('assets/images/mainpage/callender.png'),
            ),
            label: '프로필',
          ),
        ],
        //currentIndex: _selectedIndex, // 현재 선택된 인덱스
        //onTap: _onItemTapped, // 탭 선택 시 호출되는 함수
      ),
    );
  }
}
