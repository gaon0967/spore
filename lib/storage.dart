// lib/storage.dart
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage에서 주어진 경로의 이미지 URL을 가져오는 함수
Future<String> getImageUrl(String imagePath) async {
  try {
    // Firebase Storage 레퍼런스 생성
    final ref = FirebaseStorage.instance.ref().child(imagePath);
    
    // 다운로드 URL 가져오기
    final url = await ref.getDownloadURL();
    
    return url;
  } on FirebaseException catch (e) {
    // 에러 발생 시 처리
    print('Firebase Storage에서 URL을 가져오는 중 오류가 발생했습니다: $e');
    rethrow; // 에러를 다시 던져서 호출한 곳에서 처리할 수 있도록 함
  }
}