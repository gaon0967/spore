/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

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
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// Paste this entire code block into your empty index.js file
// index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 이메일로 친구를 조회하고, 친구 관계가 확인되면 프로필 정보를 반환하는 함수
exports.getFriendProfileByEmail = functions.region("asia-northeast3")
    .https.onCall(async (data, context) => {
      // 1. 요청자 인증 확인
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "This function must be called while authenticated.",
        );
      }
      const requestingUid = context.auth.uid; // 함수를 호출한 사용자의 UID

      // 2. 입력된 이메일 유효성 검사
      const email = data.email;
      if (!email || typeof email !== "string") {
        throw new functions.https.HttpsError(
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
          return { success: false, message: "User not found." };
        }

        const targetUserDoc = userQuerySnapshot.docs[0];
        const targetUid = targetUserDoc.id;
        const targetUserData = targetUserDoc.data();

        // 자기 자신을 조회하는 경우
        if (requestingUid === targetUid) {
            return { success: false, message: "You cannot search for yourself." };
        }


        // 4. 친구 관계 확인 
        const friendDoc = await admin.firestore()
            .collection("users").doc(requestingUid) // 내 UID
            .collection("friends").doc(targetUid)   // 친구 UID
            .get();

        // 5. 결과 분기 처리
        if (!friendDoc.exists) {
          // 친구 목록에 대상 사용자가 없음
          return { success: false, message: "This user is not on your friends list." };
        } else {
          
            // 친구 관계는 확인됨. 이제 차단 상태를 확인.
            const friendData = friendDoc.data(); // 친구 문서의 데이터 가져오기

          if (friendData.blockStatus === true) {
            // blockStatus가 true이면, 친구가 아닌 것처럼 처리
            return { success: false, message: "Could not retrieve user information." };
          }
          
          return {
            success: true,
            // UID는 절대 반환하지 않습니다.
            name: targetUserData.name, // 사용자 이름 . user에 있음. 
            //profileImageUrl: targetUserData.profileImageUrl, // 프로필 이미지 : 아직 필드에 없어서 못넣음.
            intro: targetUserData.intro|| "",   // 한줄 소개 필드 . user에 있음
            //title: targetUserData.title,                 // 타이틀 필드 (아직 db에 없어서 못 넣음)
          };
        }
      } catch (error) {
        console.error("Error searching for user:", error);
        throw new functions.https.HttpsError(
            "internal",
            "An error occurred while searching for the user.",
        );
      }
    });