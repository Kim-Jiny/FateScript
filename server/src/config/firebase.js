import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

if (!admin.apps.length) {
  let serviceAccount;

  // 1) 환경변수 JSON 문자열
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    // 2) 파일에서 읽기 (server/firebase-service-account.json)
    try {
      const __dirname = dirname(fileURLToPath(import.meta.url));
      const filePath = join(__dirname, '../../firebase-service-account.json');
      serviceAccount = JSON.parse(readFileSync(filePath, 'utf8'));
    } catch {
      console.error('[Firebase] ⚠️  No service account found (env var or file)');
      console.error('[Firebase] Token verification will fail.');
    }
  }

  admin.initializeApp(
    serviceAccount
      ? { credential: admin.credential.cert(serviceAccount) }
      : {},
  );

  console.log(
    `[Firebase] Initialized with ${serviceAccount ? `cert (project: ${serviceAccount.project_id})` : 'NO credentials'}`,
  );
}

export default admin;
