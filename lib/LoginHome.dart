import 'package:flutter/material.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:new_project_1/HomeCalendar.dart';
import 'PsychologyStart.dart'; //심리테스트 시작하는 화면 
import 'naver_auth/naverAndFirebaseAuth.dart'; 
import 'HomeCalendar.dart'; // 홈(달력) 화면 




/// 클래스 : LoginScreen
/// 목적 : 로그인 화면의 전체 UI를 구성하는 메인 위젯임.
/// 반환타입 : StatelessWidget (Scaffold를 반환)
/// 예외 : 예외 처리된거 없음. 
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEF9),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            _TopSection(), // 상단_로고 
            _ChatBubbleSection(), // 중긴_ 말풍선 
            _BottomSection(), // 하단_ 네이버 로그인 버튼 , 심리테스트 
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
class _TopSection extends StatelessWidget {
  const _TopSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        //앱 로고 이미지 
        Positioned(
          top: 70,
          child: Image.asset('assets/images/Logo.png', width: 48, height: 52),
        ),

        // 앱 소개 글
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

        //앱 이름 텍스트 
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



/// 클래스 : _ChatBubbleSection  
/// 목적 : 사용자에게 앱 설명하는 말풍선 UI를 표시  
/// 반환타입 : StatelessWidget (Stack 위젯을 반환)  
/// 예외 : 예외 없음 

// 말풍선 
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
          left: 52, top: 340,
          child: Image.asset('assets/images/talk1.png', width: 200, height: 48),
        ),
        Positioned(
          left: 52, top: 340, width: 190, height: 42,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("💬오늘 일정 뭐였지 ?? 💬", style: bubbleTextStyle),
            ),
          ),
        ),

        // --- 말풍선 2 ---
        Positioned(
          left: 82, top: 410,
          child: Image.asset('assets/images/talk2.png', width: 290, height: 48),
        ),
        Positioned(
          left: 82, top: 410, width: 282, height: 42,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text("spore 로 관리해봐! 친구들 일정도 볼 수 있대 📅", style: bubbleTextStyle),
            ),
          ),
        ),

        // --- 말풍선 3 ---
        Positioned(
          left: 51, top: 480,
          child: Image.asset('assets/images/talk3.png', width: 260, height: 48),
        ),
        Positioned(
          left: 51, top: 480, width: 251, height: 42,
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

/// 클래스 : _BottomSection  
/// 목적 :  화면 하단의 네이버 로그인 버튼과 심리테스트 페이지 이동 버튼을 구성  
/// 반환타입 : StatelessWidget (Stack 위젯을 반환)  
/// 예외 :  
///   - 네이버 로그인 도중 사용자가 취소하거나 오류 발생 시 예외 발생  
///   - 로그인 후 context가 unmounted 상태이면 화면 전환 실패  
///   - 에러 시 SnackBar로 사용자에게 안내 메시지 표시  
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
            onPressed: () async{
              print("네이버 로그인 버튼 클릭됨");
  
               // 1. AuthService 클래스의 인스턴스를 생성.
              final authService = AuthService();

        
              try {
              // 2, 로그인 전용.
              final userData = await authService.loginOnlyWithNaver();

              print("기존 회원 로그인 성공: $userData");

              //  3. context가 여전히 유효한지 확인
              if (!context.mounted) return;

              // 4. 성공 시 HomeCalendar 화면으로 이동
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeCalendar()),
    );

  } catch (e) {
  
    print("로그인 실패: $e");
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("로그인에 실패했습니다. 다시 시도해주세요.")),
    );
  }
            },
          ),
        ),

        // 계정이 없는 사람들을 위한 텍스트 버튼 
        Positioned(
          top: 675,
        
          child: InkWell(
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
        ),
      ],
    );
  }
}