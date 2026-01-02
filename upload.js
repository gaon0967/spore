const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const { getFirestore } = require('firebase-admin/firestore'); 

// Firebase Admin SDK 초기화

const serviceAccount = require('./const-0412-firebase-adminsdk-fbsvc-f916a2c090.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'const-0412.firebasestorage.app'  // Firebase 프로젝트의 버킷 URL을 입력하세요.
});

const bucket = admin.storage().bucket();
const db = getFirestore();


// 업로드할 로컬 assets 폴더의 경로
const localAssetsPath = path.join(__dirname, 'assets', 'images'); // assets/images 폴더 경로
// Cloud Storage에 저장될 기본 폴더 이름
const uploadPathPrefix = 'assets/images';

async function uploadFolder(directoryPath) {
  const files = fs.readdirSync(directoryPath);

  for (const file of files) {
    // 1. 여기서 숨김 파일을 확인하여 즉시 건너뜁니다.
    if (file.startsWith('.')) {
      console.log(`Skipping hidden file: ${file}`);
      continue; // 다음 파일로 넘어갑니다.
    }

    const localFilePath = path.join(directoryPath, file);
    const stats = fs.statSync(localFilePath);

    // 2. 항목이 디렉터리인지 확인합니다.
    if (stats.isDirectory()) {
      await uploadFolder(localFilePath);
    } else {
      // 3. 파일 업로드 로직
      const relativePath = path.relative(localAssetsPath, localFilePath);
      const destinationPath = path.join(uploadPathPrefix, relativePath);

      await bucket.upload(localFilePath, {
        destination: destinationPath,
      });
      console.log(`${localFilePath} -> ${destinationPath} 업로드 완료.`);
   // 추가 
      // 업로드된 파일의 레퍼런스를 가져옵니다.
      const fileRef = bucket.file(destinationPath);
      
      // 파일의 공개 다운로드 URL을 생성합니다.
      const [url] = await fileRef.getSignedUrl({
        action: 'read',
        expires: '03-09-2491', // 유효기간을 매우 길게 설정하여 영구적인 링크처럼 사용합니다.
      });

      // 'images'라는 컬렉션에 새 문서를 추가합니다.
      // 파일 이름과 생성된 URL을 저장합니다.
      const docRef = db.collection('images').doc();
      await docRef.set({
        fileName: file,
        url: url,
        createdAt: new Date(),
      });
      console.log(`Firestore에 URL 저장 완료: ${url}`);
      //  추가
    }
  }
}
console.log('이미지 업로드를 시작합니다...');
uploadFolder(localAssetsPath)
  .then(() => {
    console.log('🎉 모든 이미지 업로드 완료!');
  })
  .catch((error) => {
    console.error('업로드 중 오류가 발생했습니다:', error);
  });