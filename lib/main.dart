import 'package:flutter/material.dart';
//import 'package:flutter_logcat/flutter_logcat.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_project_1/HomeCalendar.dart';
//import 'package:new_project_1/naver_auth/naverAndFirebaseAuth.dart';
import 'firebase_options.dart'; // Firebase CLI로 생성된 파일
import 'LoginHome.dart';

const urlScheme = 'flutterNaverLogin'; // IOS 어플에만 이용(아직 안함)
const clientId = 'eW2zZw8AjJC4iudM9OzD'; // naver api id
const clientSecret = 'y9F8XUjPS_'; // naver api pw
const clientName = "My App"; //  appName

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // api key를 넣어줍니다.
  NaverLoginSDK.initialize(
    urlScheme: urlScheme,
    clientId: clientId,
    clientSecret: clientSecret,
    clientName: clientName,
  );

  //runApp(MaterialApp(home: const MyApp()));
  runApp(const MyApp());
}

//MyApp 위젯을 앱의 기본 설정을 담당하는 간단한 형태로 변경.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      // home  첫 화면 만듬.
      home: LoginScreen(),
      //home: HomeCalendar(),
    );
  }
}



/*
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: FittedBox(child: Text("네이버 로그인 테스트"))),
      
      
      body  : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                        padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NaverLoginButton(
                    onPressed: () {
                      AuthService a = AuthService(); // 로그인 -> 토큰 발급 -> 서버에서 인증
                      a.signInWithNaver(); // 실행 ** 가장 중요한 로직임
                    },
                    style: NaverLoginButtonStyle(
                      language: NaverButtonLanguage.korean,
                      mode: NaverButtonMode.green,
                      type: NaverButtonType.rectangleBar,
                    ),
                    width: 200,
                  ),
                  SizedBox(height: 9.0),
                  NaverLogoutButton(
                    onPressed:
                        () => NaverLoginSDK.logout(), // 로그아웃 로직. 토큰을 지워버린다.
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
                      Log.i("accessToken:$accessToken");
                    },
                    child: Text("AccessToken"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

*/