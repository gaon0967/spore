import 'package:flutter/material.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:new_project_1/HomeCalendar.dart';
import 'PsychologyStart.dart';
import 'naver_auth/naverAndFirebaseAuth.dart';
import 'HomeCalendar.dart';

// 화면 전체를 구성하는 메인 위젯
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEF9),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [_TopSection(), _ChatBubbleSection(), _BottomSection()],
        ),
      ),
    );
  }
}

// 1. 상단 섹션
class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 70,
          child: Image.asset('assets/images/Logo.png', width: 48, height: 52),
        ),
        Positioned(
          top: 140,
          child: const Text(
            "하루를 공유하고, 일정을 관리하세요.",
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF514949),
            ),
          ),
        ),
        Positioned(
          top: 160,
          child: const Text(
            "spore",
            style: TextStyle(
              fontFamily: 'League Spartan',
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B6060),
            ),
          ),
        ),
      ],
    );
  }
}

// 2. 말풍선 섹션
class _ChatBubbleSection extends StatelessWidget {
  const _ChatBubbleSection();

  @override
  Widget build(BuildContext context) {
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
          left: 52,
          top: 340,
          child: Image.asset('assets/images/talk1.png', width: 190, height: 42),
        ),
        Positioned(
          left: 52,
          top: 340,
          width: 190,
          height: 42,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("오늘 일정 뭐였지 ?? 💬", style: bubbleTextStyle),
            ),
          ),
        ),

        // --- 말풍선 2 ---
        Positioned(
          left: 82,
          top: 410,
          child: Image.asset('assets/images/talk2.png', width: 282, height: 42),
        ),
        Positioned(
          left: 82,
          top: 410,
          width: 282,
          height: 42,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(
                "spore 로 관리해봐! 친구들 일정도 볼 수 있대 📅",
                style: bubbleTextStyle,
              ),
            ),
          ),
        ),

        // --- 말풍선 3 ---
        Positioned(
          left: 51,
          top: 480,
          child: Image.asset('assets/images/talk3.png', width: 251, height: 42),
        ),
        Positioned(
          left: 51,
          top: 480,
          width: 251,
          height: 42,
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

// 하단 네이버 로그인 _ 네이버 가이드 라인이 있어서 로고 모양 추후 다시 알아보고 변경. _ 원, 직사각형만 됨.
class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 600,
          child: NaverLoginButton(
            style: NaverLoginButtonStyle(
              mode: NaverButtonMode.green,
              type: NaverButtonType.rectangleBar,
            ),
            width: 302,
            height: 55,
            onPressed: () async {
              print("네이버 로그인 버튼 클릭됨");

              // 1. AuthService 클래스의 인스턴스를 생성합니다.
              final authService = AuthService();
              // 2. try-catch 블록으로 로그인 과정 전체를 감싸 에러를 처리합니다.
              try {
                // 3. '로그인 전용' 메소드를 호출합니다.
                final userData = await authService.signInWithNaver(-1);

                print("유저 등록 성공: $userData");
                // 위젯이 화면에 마운트된 상태인지 확인 (안전장치)
                if (!context.mounted) return;
                // 심리테스트 여부를 '-1'로 확인
                if (userData['characterId'] as int == -1) {
                  print('신규유저 등록 후 심리테스트 진행');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PsychologyStart(),
                    ),
                  );
                } else {
                  print('기존 유저 홈화면 이동');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeCalendar(),
                    ),
                  );
                }
              } catch (e) {
                // 사용자가 로그인을 취소했거나 에러가 발생한 경우
                print("로그인 실패: $e");
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("로그인에 실패했습니다. 다시 시도해주세요.")),
                );
              }
            },
          ),
        ),
        Positioned(
          top: 675,
          // Text 위젯을 InkWell로 감싸서 탭 가능하게 만듭니다.
          child: InkWell(
            onTap: () {
              // onTap 콜백에서 Navigator.push를 호출해 화면을 이동시킵니다.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PsychologyStart(),
                ),
              );
            },
            // 시각적인 터치 효과를 위해 투명한 배경을 줍니다.
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
        ),
      ],
    );
  }
}
