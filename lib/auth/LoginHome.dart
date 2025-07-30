import 'package:flutter/material.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:new_project_1/features/Calendar/HomeCalendar.dart';
import '../features/Psychology/PsychologyStart.dart'; //심리테스트 시작하는 화면
import 'naverAndFirebaseAuth.dart';
import 'package:new_project_1/features/Home/main_screen.dart';

/// 클래스 : LoginScreen
/// 목적 : 로그인 화면의 전체 UI를 구성하는 메인 위젯임.
/// 반환타입 : StatelessWidget (Scaffold를 반환)
/// 예외 : 예외 처리된거 없음.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFFFFFEF9),
      body: SafeArea(
        child: Column(
          children: [
            _TopSection(), //  상단 섹션

            SizedBox(height: screenHeight * 0.08), //  남는 세로 공간

            _ChatBubbleSection(), //  말풍선 섹션

            SizedBox(height: screenHeight * 0.1), // 남는 세로 공간

            _BottomSection(), // 하단 섹션

            SizedBox(height: screenHeight * 0.08), // 하단에 여백
          ],
        ),
      ),
    );
  }
}

/// 클래스 : _TopSection
/// 목적 : 로그인 화면 상단의 로고와 앱 이름, 설명를 표시하는 섹션 위젯
/// 반환타입 : StatelessWidget (Stack 위젯을 반환)
/// 예외 : 예외 처리된거 없음.
/// 수정_반응형으로 변경 (Stack + Positioned → Padding + Column)
class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/LoginHome/Logo.png',
            width: screenWidth * 0.12,
          ),
          const SizedBox(height: 15),
          const Text(
            "하루를 공유하고, 일정을 관리하세요.",
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF514949),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "spore",
            style: TextStyle(
              fontFamily: 'League Spartan',
              fontSize: screenWidth * 0.11,
              fontWeight: FontWeight.w900, // bold 에서 수정.
              color: const Color(0xFF6B6060),
            ),
          ),
        ],
      ),
    );
  }
}

/// 클래스 : _ChatBubbleSection
/// 목적 : 사용자에게 앱 설명하는 말풍선 UI를 표시
/// 반환타입 : StatelessWidget (Stack 위젯을 반환)
/// 예외 : 예외 없음

// 말풍선

/*
class _ChatBubbleSection extends StatelessWidget {
  const _ChatBubbleSection();

  @override
  Widget build(BuildContext context) {
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    
    
    const bubbleTextStyle = TextStyle(

    
      fontFamily: 'Golos Text',
      fontSize: 12,
      color: Color(0xFF777575),
      fontWeight: FontWeight.w500,
    );

    return Stack(
      children: [
        // --- 말풍선 1 ---
        Positioned(
          //left: 52, top: 340, 고정형임.

           left: screenWidth * 0.13,
           top: screenHeight * 0.45,
          child: Image.asset('assets/images/talk1.png', width: screenWidth * 0.5, height: screenHeight * 0.06,),
        ),
        Positioned(
          //left: 52, top: 340, width: 190, height: 42,

          left: screenWidth * 0.13,
          top: screenHeight * 0.45,
          width: screenWidth * 0.47,
          height: screenHeight * 0.05,

          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("💬오늘 일정 뭐였지 ?? 💬", style: bubbleTextStyle),
            ),
          ),
        ),

        // --- 말풍선 2 ---
        Positioned(
          left: screenWidth * 0.21,
           top: screenHeight * 0.54,

          child: Image.asset('assets/images/talk2.png', width: screenWidth * 0.75, height: screenHeight * 0.06) 
          ),
        Positioned(
          //left: 82, top: 410, width: 282, height: 42,

          
          left: screenWidth * 0.21,
          top: screenHeight * 0.54,
          width: screenWidth * 0.73,
          height: screenHeight * 0.055,

          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("spore 로 관리해봐! 친구들 일정도 볼 수 있대 📅", style: bubbleTextStyle),
            ),
          ),
        ),

        // --- 말풍선 3 ---
        Positioned(
          //left: 51, top: 480,

          left: screenWidth * 0.13,
          top: screenHeight * 0.63,

          child: Image.asset('assets/images/talk3.png', width: screenWidth * 0.68,height: screenHeight * 0.06,),
        ),
        Positioned(
          //left: 51, top: 480, width: 251, height: 42,
          left: screenWidth * 0.13,
          top: screenHeight * 0.632,
          width: screenWidth * 0.66,
          height: screenHeight * 0.055,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("새로운 친구들을 만날 수 있어서 좋네 👥", style: bubbleTextStyle),
            ),
          ),
        ),
      ],
    );
  }
}
*/

class _ChatBubbleSection extends StatelessWidget {
  const _ChatBubbleSection();

  // 말풍선을 만드는 재사용 가능한 함수
  Widget _buildChatBubble({
    required BuildContext context,
    required String imagePath,
    required String text,
    required Alignment alignment,
    required double imageWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    const bubbleTextStyle = TextStyle(
      fontFamily: 'Golos Text',
      fontSize: 12,
      color: Color(0xFF777575),
      fontWeight: FontWeight.w500,
    );

    return Align(
      alignment: alignment,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 이미지의 너비를 반응형으로 설정합니다.
          Image.asset(imagePath, width: screenWidth * imageWidth),
          // 텍스트에 좌우, 하단 여백을 주어 이미지 중앙에 예쁘게 배치합니다.
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 15, right: 15),
            child: Text(
              text,
              style: bubbleTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        children: [
          _buildChatBubble(
            context: context,
            imagePath: 'assets/images/LoginHome/talk1.png',
            text: "💬오늘 일정 뭐였지 ?? 💬",
            alignment: Alignment.centerLeft,
            imageWidth: 0.5, // 원본 이미지 너비 비율
          ),
          const SizedBox(height: 20),
          _buildChatBubble(
            context: context,
            imagePath: 'assets/images/LoginHome/talk2.png',
            text: "spore 로 관리해봐! 친구들 일정도 볼 수 있대 📅",
            alignment: Alignment.centerRight,
            imageWidth: 0.75, // 원본 이미지 너비 비율
          ),
          const SizedBox(height: 20),
          _buildChatBubble(
            context: context,
            imagePath: 'assets/images/LoginHome/talk3.png',
            text: "새로운 친구들을 만날 수 있어서 좋네 👥",
            alignment: Alignment.centerLeft,
            imageWidth: 0.68, // 원본 이미지 너비 비율
          ),
        ],
      ),
    );
  }
}

// 하단 네이버 로그인 _ 네이버 가이드 라인이 있어서 로고 모양 추후 다시 알아보고 변경. _ 원, 직사각형만 됨.

/// 클래스 : _BottomSection
/// 목적 :  화면 하단의 네이버 로그인 버튼과 심리테스트 페이지 이동 버튼을 구성
/// 반환타입 : StatelessWidget (Stack 위젯을 반환)
/// 예외 :
///   - 네이버 로그인 도중 사용자가 취소하거나 오류 발생 시 예외 발생
///   - 로그인 후 context가 unmounted 상태이면 화면 전환 실패
///   - 에러 시 SnackBar로 사용자에게 안내 메시지 표시
/// 수정이 Stack, Positioned -> Column
class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 반응형
    final default_id = -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NaverLoginButton(
          style: NaverLoginButtonStyle(
            mode: NaverButtonMode.green,
            type: NaverButtonType.rectangleBar,
          ),

          width: screenWidth * 0.8,
          height: 55,
          onPressed: () async {
            print("네이버 로그인 버튼 클릭됨");

            // 1. AuthService 클래스의 인스턴스를 생성.
            final authService = AuthService();

            try {
              // 2, 로그인 전용.
              
              final userData = await authService.signInWithNaver(default_id);

              if (userData["characterId"] == -1) {
                if (!context.mounted) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PsychologyStart(),
                  ),
                );
              } else {
                if (!context.mounted) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              }
            } catch (e) {
              print("로그인 실패: $e");
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("로그인에 실패했습니다. 다시 시도해주세요.")),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        // 계정이 없는 사람들을 위한 텍스트 버튼
        InkWell(
          onTap: () {
            // 심리 테스트 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PsychologyStart()),
            );
          },

          splashColor: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              "계정이 없다면? 심리테스트 바로가기 →",
              style: TextStyle(
                fontFamily: 'Golos Text',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7B7B7B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
