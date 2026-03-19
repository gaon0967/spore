//가령: email 추가및 삭제를 위한 코드 (250319)
import 'package:cloud_functions/cloud_functions.dart';

class EmailVerificationService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast3',
  );

  /// 인증번호 발송
  static Future<String> sendCode(String email) async {
    final callable = _functions.httpsCallable('sendVerificationCode');
    final result = await callable.call({'email': email});
    return result.data['message'] as String;
  }

  /// 인증번호 확인 및 이메일 등록
  static Future<String> verifyCode(String code) async {
    final callable = _functions.httpsCallable('verifyEmailCode');
    final result = await callable.call({'code': code});
    return result.data['email'] as String;
  }
}
