import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

class AuthService {
  // 네이버 로그인 후 토큰을 받고 유저를 저장하는 함수
  Future<void> signInWithNaver() async {
    try {
      await NaverLoginSDK.authenticate(
        // NaverLoginSDK 를 이용해 로그인에 시도 후 토큰을 받아온다.
        callback: OAuthLoginCallback(
          onSuccess: () async {
            final accessToken = await NaverLoginSDK.getAccessToken();
            if (accessToken.isEmpty) {
              throw Exception('Naver accessToken is empty.');
            }
            print('Naver accessToken: $accessToken');

            // 유저 정보를 가져오는 함수
            await NaverLoginSDK.profile(
              // 유저의 profile을 가져온다.
              callback: ProfileCallback(
                onSuccess: (resultCode, message, response) async {
                  print('Profile: $response');
                  final profile = NaverLoginProfile.fromJson(
                    response: response,
                  );
                  print(
                    'User: ${profile.id}, ${profile.email}, ${profile.name}',
                  );

                  await _callFirebaseFunction(
                    // 토큰과 유저 정보를 넘김.
                    accessToken,
                    profile,
                  ); // ** 중요한 로직. firebase functions에 연결해 인증을 받고 db와 연동함.
                },
                onError: (errorCode, message) {
                  throw Exception('Profile error: $errorCode, $message');
                },
                onFailure: (httpStatus, message) {
                  throw Exception('Profile failure: $httpStatus, $message');
                },
              ),
            );
          },
          onError: (errorCode, message) {
            throw Exception('Login error: $errorCode, $message.');
          },
          onFailure: (httpStatus, message) {
            throw Exception('Login failure: $httpStatus, $message.');
          },
        ),
      );
    } catch (e) {
      print('Error: $e');
      throw Exception('로그인 실패. 로직 검토 : $e');
    }
  }

  Future<void> _callFirebaseFunction(
    String accessToken,
    NaverLoginProfile profile,
  ) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'createCustomToken',
      ); // firebase functions의 createCustomToken 함수를 실행시킨다.

      final response = await callable.call({'accessToken': accessToken});
      print('Firebase Function response: ${response.data}'); // 요청 받아온 값을 출력

      // response 에서 값을 가져온다.
      final customToken = response.data['customToken'];
      final email = response.data['email'];
      final name = response.data['name'];
      final phoneNumber = response.data['phoneNumber'];
      final uid = response.data['uid'];

      if (customToken == null) {
        throw Exception('No customToken returned from server.');
      }

      // 서버에서 인증하여 받아온 토큰으로 firebase에 인증한다다
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      // 유저에 저장할 목록은 map 형식으로 만듦.
      final userDoc = <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      print("userDoc : ${userDoc}");

      // 데이터베이스 이름 : takch02, app : 기존 앱
      FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
        databaseId: "takch02",
        app: Firebase.app(),
      );
      // 저장
      await _firestore.collection('users').add(userDoc);
    } catch (e) {
      print('Error: $e');
      throw Exception('Function call fucked up, Q삣삐: $e');
    }
  }
}
