import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

// 네이버 API 응답 타입 정의
// id, email, name, phoneNumber 를 flutter로 넘긴다.
interface NaverProfileResponse {
  resultcode: string;
  message: string;
  response: {
    id: string;
    email?: string;
    name?: string;
    mobile?: string;
  };
}

// 입력 데이터 타입 정의
interface CustomTokenInput {
  accessToken: string;
}

// 출력 데이터 타입 정의
interface CustomTokenOutput {
  customToken: string;
  uid: string;
  email: string;
  name: string;
  phoneNumber: string;
}

// JSON 직렬화에서 순환 참조 처리
const safeStringify = (obj: unknown): string => {
  const cache = new Set();
  return JSON.stringify(obj, (key, value) => {
    if (typeof value === 'object' && value !== null) {
      if (cache.has(value)) {
        return '[Circular]';
      }
      cache.add(value);
    }
    return value;
  }, 2);
};

// Firebase Admin 초기화
admin.initializeApp();

// HTTPS Callable Function: 네이버 토큰으로 커스텀 토큰 생성
// 클래스 : X
// 목적 : 네이버 로그인 후 토큰 유효성 검토. 검토 후 fireAuth로 넘겨 인증!
// 반환 타입 : Object (JS 모르시는 분이면 객체를 반환한다 생각해주세요)
// 예외 : http에서 받은 JSON 형식 오류, 토근이 유효하지 않을 시 발생
export const createCustomToken = functions.https.onCall(
  async (data: unknown): Promise<CustomTokenOutput> => {
    // 디버깅: 수신된 데이터 로그
    console.log('Received data:', safeStringify(data));

    // 입력 데이터 추출 (Callable Functions 또는 HTTP POST 처리)
    let inputData: unknown = data;
    if (data && typeof data === 'object' && 'data' in data) {
      console.log('Extracting nested data field');
      inputData = (data as any).data;
    }

    // 입력 데이터 유효성 검사
    if (
      !inputData ||
      typeof inputData !== 'object' ||
      !('accessToken' in inputData) ||
      typeof (inputData as CustomTokenInput).accessToken !== 'string' ||
      (inputData as CustomTokenInput).accessToken.trim() === ''
    ) {
      console.error('Invalid or missing accessToken:', safeStringify(data));
      throw new functions.https.HttpsError('invalid-argument', 'No valid accessToken provided. Check your client code.');
    }
    const naverAccessToken = (inputData as CustomTokenInput).accessToken;

    try {
      // 네이버 API로 유저 정보 가져오기
      const response = await axios.get<NaverProfileResponse>('https://openapi.naver.com/v1/nid/me', {
        headers: {
          Authorization: `Bearer ${naverAccessToken}`,
        },
      });
      console.log('Naver API response:', safeStringify(response.data));

      const userData = response.data.response;
      if (!userData || !userData.id) {
        console.error('Invalid Naver profile data:', safeStringify(response.data));
        throw new functions.https.HttpsError('unauthenticated', 'Failed to retrieve valid Naver profile data.');
      }

      const uid = userData.id;
      const email = userData.email ?? 'unknown';
      const name = userData.name ?? 'No Name';
      const phoneNumber = userData.mobile ?? '';

      // UID 유효성 검사 (Firebase UID: 최대 128자, ASCII 문자)
      if (uid.length > 128 || !/^[ -~]+$/.test(uid)) {
        console.error('Invalid UID format:', uid);
        throw new functions.https.HttpsError('invalid-argument', 'Invalid UID format from Naver profile.');
      }
      
      // 커스텀 토큰 생성
      let customToken: string;
      try {
        customToken = await admin.auth().createCustomToken(uid);
        console.log('Generated customToken for UID:', uid);
      } catch (error: any) {
        console.error('Custom token creation error:', error);
        throw new functions.https.HttpsError('permission-denied', `Failed to create custom token: ${error.message}`);
      }

      return {
        customToken,
        uid,
        email,
        name,
        phoneNumber,
      };
    } catch (error: any) {
      console.error(
        'Error verifying Naver token:',
        error.response ? safeStringify(error.response.data) : error.message
      );
      throw new functions.https.HttpsError('internal', `Failed to verify Naver token: ${error.message}`);
    }
  }
);