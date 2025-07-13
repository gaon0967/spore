import 'package:flutter/material.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

int _selectedIndex = 0; // 현재 선택된 탭 인덱스

class HomeCalendar extends StatelessWidget {
  const HomeCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(title: const Text("메인 화면")),
      body: Center(
        child: Column(
          children: [
            NaverLogoutButton(
              onPressed: () => NaverLoginSDK.logout(), // 로그아웃 로직. 토큰을 지워버린다.
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
                    await NaverLoginSDK.getAccessToken(); // 현재 토큰이 있는지 즉 로그인 상태인지 확인하는 로직
                print("accessToken:$accessToken");
              },
              child: Text("AccessToken"),
            ),
          ],
        ),
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
