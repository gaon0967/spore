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

  //Future<Map> signInWithNaver() async {

  Future<Map> signInWithNaver(int characterId) async {
    // 캐릭터id를 인자로 받게 수정 _ 가령

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
      return await _callFirebaseFunction(
        accessToken,
        profile,
        characterId,
      ); //characterId: characterId 추가 _ 가령
    } catch (e) {
      print('Error: $e');
      throw Exception('로그인 실패: $e');
    }
  }

  // 로그인만 되는 함수 추가 _ 가령
  /// 함수: loginOnlyWithNaver()
  /// 목적: 기존 회원만 Naver 소셜 로그인을 진행한다. DB에 유저가 없으면 에러를 발생시킨다.
  /**Future<Map<String, dynamic>> update_CharacterId() async {
    try {

      // 2. Firebase 함수 호출
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('createCustomToken');
      final response = await callable.call({'accessToken': accessToken});
      final uid = response.data['uid'];
      final customToken = response.data['customToken'];

      if (customToken == null) {
        throw Exception('No customToken returned from server.');
      }

      // 3. Firebase Auth 로그인
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      // 4. Firestore 사용자 확인
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      // 5. 사용자 존재 여부 확인 후 결과 반환
      if (userDoc.exists) {
        return userDoc.data() ?? {};
      } else {
        await NaverLoginSDK.logout();
        await FirebaseAuth.instance.signOut();
        throw Exception('가입된 정보가 없습니다. 설문조사를 통해 먼저 회원가입을 진행해주세요.');
      }
    } catch (e) {
      rethrow;
    }
  }
**/
  /// 함수 : callFirebaseFunction()
  /// 목적 : 토큰, 프로파일을 firebase에 넘겨 유저가 없으면 생성한다. 유저의 정보가 담긴 Map을 return 한다.
  /// 반환타입 : Map<dynaic, dynamic>
  /// 예외 : 토큰이 없거나 프로파일이 없는 경우 발생
  Future<Map> _callFirebaseFunction(
    String accessToken,
    NaverLoginProfile profile,
    int characterId,
  ) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
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
        'characterId': characterId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      print("유저 정보가 있는지 : ${userDocSnapShot.exists}");
      if (!userDocSnapShot.exists) {
        // 로그인 정보가 있는 경우에 다시 심리 테스트 한 경우 , 정보 업데이트 되게 _ 가령
        // 신규 유저(회원가입): 문서를 새로 생성 (set)
        await userRef.set(userDoc);
      } else if (characterId != -1) {
        await userRef.update(userDoc);
      }

      final updatedUserDoc = await userRef.get();
      print("로그인 단계 : ${updatedUserDoc.data()}");
      return updatedUserDoc.data() ?? {};
    } catch (e) {
      print('Error: $e');
      throw Exception('Function call error: $e');
    }
  }
}
