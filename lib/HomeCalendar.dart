import 'package:flutter/material.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'TimetableScreen.dart'; // TimetableScreen 파일을 import 합니다.

int _selectedIndex = 0; // 현재 선택된 탭 인덱스

class HomeCalendar extends StatefulWidget {
  const HomeCalendar({super.key});

  @override
  _HomeCalendarState createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  // 탭을 클릭할 때마다 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // '프로필' 탭 (인덱스 2) 클릭 시 TimetableScreen으로 이동
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimetableScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(title: const Text("메인 화면")),
      body: Center(
        child: Column(
          children: [
            NaverLogoutButton(
              onPressed: () => NaverLoginSDK.logout(), // 로그아웃 로직
              style: NaverLogoutButtonStyle(
                language: NaverButtonLanguage.korean,
                mode: NaverButtonMode.green,
              ),
              width: 200,
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () async {
                final accessToken =
                    await NaverLoginSDK.getAccessToken(); // 로그인 상태 확인
                print("accessToken:$accessToken");
              },
              child: Text("AccessToken"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // 현재 선택된 탭 인덱스
        onTap: _onItemTapped, // 탭을 눌렀을 때 호출되는 함수
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
      ),
    );
  }
}
