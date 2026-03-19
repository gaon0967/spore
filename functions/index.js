/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
// const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// Paste this entire code block into your empty index.js file
// index.js

const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
require("dotenv").config();

admin.initializeApp();

// 가령: email 추가및 삭제를 위한 코드 (250319)
// Gmail SMTP 설정
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.SMTP_EMAIL,
    pass: process.env.SMTP_PASSWORD,
  },
});

// 가령: email 추가및 삭제를 위한 코드 (250319)
const {onCall, HttpsError} = require("firebase-functions/v2/https");

// 인증번호 발송
exports.sendVerificationCode = onCall(
    {region: "asia-northeast3"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated", "로그인이 필요합니다.",
        );
      }
      const uid = request.auth.uid;
      const email = request.data.email;

      if (!email || typeof email !== "string") {
        throw new HttpsError(
            "invalid-argument", "유효한 이메일을 입력해주세요.",
        );
      }

      // 이미 다른 유저가 사용 중인 이메일인지 확인
      const existingUser = await admin.firestore()
          .collection("users")
          .where("email", "==", email)
          .limit(1)
          .get();
      if (!existingUser.empty) {
        const existingUid = existingUser.docs[0].id;
        if (existingUid !== uid) {
          throw new HttpsError(
              "already-exists",
              "이미 사용 중인 이메일입니다.",
          );
        }
      }

      // 6자리 인증번호 생성
      const code = Math.floor(
          100000 + Math.random() * 900000,
      ).toString();

      // Firestore에 인증번호 저장 (5분 만료)
      await admin.firestore()
          .collection("email_verifications")
          .doc(uid)
          .set({
            email: email,
            code: code,
            createdAt: admin.firestore
                .FieldValue.serverTimestamp(),
            expiresAt: new Date(
                Date.now() + 5 * 60 * 1000,
            ),
          });

      // 이메일 발송
      await transporter.sendMail({
        from: "Spore <sporeapplication2026@gmail.com>",
        to: email,
        subject: "[Spore] 이메일 인증번호",
        html: "<div style=\"font-family: sans-serif;" +
          " padding: 20px;\">" +
          "<h2>Spore 이메일 인증</h2>" +
          "<p>인증번호: <strong style=\"font-size:" +
          " 24px;\">" + code + "</strong></p>" +
          "<p>5분 이내에 입력해주세요.</p></div>",
      });

      return {
        success: true,
        message: "인증번호가 발송되었습니다.",
      };
    },
);

// 인증번호 확인 및 이메일 등록
exports.verifyEmailCode = onCall(
    {region: "asia-northeast3"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated", "로그인이 필요합니다.",
        );
      }
      const uid = request.auth.uid;
      const code = request.data.code;

      if (!code || typeof code !== "string") {
        throw new HttpsError(
            "invalid-argument",
            "인증번호를 입력해주세요.",
        );
      }

      // Firestore에서 인증 정보 조회
      const verDoc = await admin.firestore()
          .collection("email_verifications")
          .doc(uid)
          .get();

      if (!verDoc.exists) {
        throw new HttpsError(
            "not-found",
            "인증 요청을 찾을 수 없습니다.",
        );
      }

      const verData = verDoc.data();

      // 만료 확인
      if (verData.expiresAt.toDate() < new Date()) {
        await admin.firestore()
            .collection("email_verifications")
            .doc(uid).delete();
        throw new HttpsError(
            "deadline-exceeded",
            "인증번호가 만료되었습니다.",
        );
      }

      // 코드 일치 확인
      if (verData.code !== code) {
        throw new HttpsError(
            "permission-denied",
            "인증번호가 일치하지 않습니다.",
        );
      }

      // 이메일을 유저 문서에 저장
      await admin.firestore()
          .collection("users")
          .doc(uid)
          .update({email: verData.email});

      // 인증 문서 삭제
      await admin.firestore()
          .collection("email_verifications")
          .doc(uid).delete();

      return {success: true, email: verData.email};
    },
);

// 이메일로 친구를 조회하고, 친구 관계가 확인되면 프로필 정보를 반환하는 함수
exports.getFriendProfileByEmail = onCall(
    {region: "asia-northeast3"},
    async (request) => {
      // 1. 요청자 인증 확인
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "This function must be called while authenticated.",
        );
      }
      const requestingUid = request.auth.uid;

      // 2. 입력된 이메일 유효성 검사
      const email = request.data.email;
      if (!email || typeof email !== "string") {
        throw new HttpsError(
            "invalid-argument",
            "The function must be called with a valid email.",
        );
      }

      try {
        // 3. 이메일로 대상 친구 조회
        const userQuerySnapshot = await admin.firestore()
            .collection("users")
            .where("email", "==", email)
            .limit(1)
            .get();

        // 대상 사용자가 존재하지 않으면 종료
        if (userQuerySnapshot.empty) {
          return {success: false, message: "User not found."};
        }

        const targetUserDoc = userQuerySnapshot.docs[0];
        const targetUid = targetUserDoc.id;
        const targetUserData = targetUserDoc.data();

        // 자기 자신을 조회하는 경우
        if (requestingUid === targetUid) {
          return {success: false, message: "You cannot search for yourself."};
        }


        // 4. 친구 관계 확인
        const friendDoc = await admin.firestore()
            .collection("users").doc(requestingUid) // 내 UID
            .collection("friends").doc(targetUid) // 친구 UID
            .get();

        // 5. 결과 분기 처리
        if (!friendDoc.exists) {
          // 친구 목록에 대상 사용자가 없음
          return {
            success: false,
            message: "This user is not on your friends list.",
          };
        } else {
          // 친구 관계는 확인됨. 이제 차단 상태를 확인.
          const friendData = friendDoc.data(); // 친구 문서의 데이터 가져오기

          if (friendData.blockStatus === true) {
            // blockStatus가 true이면, 친구가 아닌 것처럼 처리
            return {
              success: false,
              message: "Could not retrieve user information.",
            };
          }

          return {
            success: true,
            // UID는 절대 반환하지 않습니다.
            // 사용자 이름
            name: targetUserData.name,
            // 한줄 소개
            intro: targetUserData.intro || "",
          };
        }
      } catch (error) {
        console.error("Error searching for user:", error);
        throw new HttpsError(
            "internal",
            "An error occurred while searching.",
        );
      }
    },
);
