import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';

const database_Id = '(default)'; // 데이터베이스 이름

/// 클래스 : AuthService
/// 목적 : Naver 소셜 로그인으로 로그인하고 유저 정보를 return 한다.
/// 반환타입 : Map<String, dynamic>
/// 예외 : Naver 로그인에 실패 or 토큰이 없거나 프로파일이 없는 경우 발생
class AuthService {
  /// 클래스 : signInWithNaver()
  /// 목적 : Naver 소셜 로그인으로 로그인하고 유저 정보를 return 한다.
  /// 반환타입 : Map<String, dynamic>
  /// 예외 : Naver 로그인에 실패 or 토큰이 없거나 프로파일이 없는 경우 발생
  Future<Map> signInWithNaver() async {
    try {
      // 네이버 로그인 인증
      String accessToken = '';
      dynamic profile = '';
      await NaverLoginSDK.authenticate(
        // NaverLoginSDK 를 이용해 로그인에 시도 후 토큰을 받아온다.
        callback: OAuthLoginCallback(
          onSuccess: () async {
            final token = await NaverLoginSDK.getAccessToken();
            if (token.isEmpty) {
              throw Exception('Naver accessToken is empty.');
            }
            print('Naver accessToken: $token');
            accessToken = token;
          },
          onError: (errorCode, message) {
            throw Exception('Login error: $errorCode, $message');
          },
          onFailure: (httpStatus, message) {
            throw Exception('Login failure: $httpStatus, $message');
          },
        ),
      );

      // 네이버 프로필 가져오기
      await NaverLoginSDK.profile(
        callback: ProfileCallback(
          onSuccess: (resultCode, message, response) async {
            print('Profile: $response');
            profile = NaverLoginProfile.fromJson(response: response);
          },
          onError: (errorCode, message) {
            throw Exception('Profile error: $errorCode, $message');
          },
          onFailure: (httpStatus, message) {
            throw Exception('Profile failure: $httpStatus, $message');
          },
        ),
      );
      // 예외처리
      if (accessToken == '' || profile == '') {
        throw Exception('사용자 로그인 실패');
      }
      return await _callFirebaseFunction(accessToken, profile);
    } catch (e) {
      print('Error: $e');
      throw Exception('로그인 실패: $e');
    }
  }

  /// 함수 : callFirebaseFunction()
  /// 목적 : 토큰, 프로파일을 firebase에 넘겨 유저가 없으면 생성한다. 유저의 정보가 담긴 Map을 return 한다.
  /// 반환타입 : Map<dynaic, dynamic>
  /// 예외 : 토큰이 없거나 프로파일이 없는 경우 발생
  Future<Map> _callFirebaseFunction(
    String accessToken,
    NaverLoginProfile profile,
  ) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'createCustomToken',
      ); // firebase functions의 createCustomToken 함수를 실행시킨다.
      print("okok");
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

      // 서버에서 인증하여 받아온 토큰으로 firebase에 인증한다
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      // 데이터베이스 이름 : (default), app : 기존 앱
      FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
        databaseId: database_Id,
        app: Firebase.app(),
      );

      /**
       * userRef에 문서Id가 uid인 값을 가져온다.
       * get() 의 값이 없으면 유저를 만듦.(회원가입)
       * 
       */

      final userRef = _firestore.collection('users').doc(uid);
      final userDocSnapShot = await userRef.get();
      final userDoc = <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userDocSnapShot.exists) {
        await userRef.set(userDoc);
      }
      return userDoc;
    } catch (e) {
      print('Error: $e');
      throw Exception('Function call error: $e');
    }
  }
}
