/**
 * In-App Purchase 영수증 검증
 * - Apple: App Store verifyReceipt API
 * - Google: Play Developer API (androidpublisher)
 */

import { google } from 'googleapis';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const APPLE_VERIFY_PRODUCTION = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_VERIFY_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';
const IOS_BUNDLE_ID = 'com.unmyeongilgi.unmyeongilgi';
const ANDROID_PACKAGE_NAME = 'com.unmyeongilgi.unmyeongilgi';

// ── Apple 영수증 검증 ──

async function verifyAppleReceipt(receiptData) {
  console.log(`[IAP:Apple] 영수증 검증 시작 (receipt 길이: ${receiptData?.length || 0})`);

  // Production 먼저 시도, 21007이면 Sandbox로 재시도
  let result = await callAppleVerify(APPLE_VERIFY_PRODUCTION, receiptData);
  console.log(`[IAP:Apple] Production 응답 status: ${result.status}`);

  if (result.status === 21007) {
    // Sandbox 영수증 → Sandbox 서버로 재시도
    console.log('[IAP:Apple] Sandbox 영수증 감지 → Sandbox 서버로 재시도');
    result = await callAppleVerify(APPLE_VERIFY_SANDBOX, receiptData);
    console.log(`[IAP:Apple] Sandbox 응답 status: ${result.status}`);
  }

  if (result.status !== 0) {
    console.error(`[IAP:Apple] 검증 실패 — status: ${result.status}, 전체 응답:`, JSON.stringify(result).substring(0, 500));
    throw new Error(`Apple 영수증 검증 실패 (status: ${result.status})`);
  }

  // bundle_id 확인
  const bundleId = result.receipt?.bundle_id;
  console.log(`[IAP:Apple] bundle_id: ${bundleId}, 기대값: ${IOS_BUNDLE_ID}`);
  if (bundleId !== IOS_BUNDLE_ID) {
    throw new Error(`Bundle ID 불일치: ${bundleId}`);
  }

  // in_app 항목에서 product_id 추출
  const inApp = result.receipt?.in_app ?? result.latest_receipt_info ?? [];
  console.log(`[IAP:Apple] in_app 항목 수: ${inApp.length}`);
  if (inApp.length === 0) {
    console.error('[IAP:Apple] 구매 항목 없음. receipt 키:', Object.keys(result.receipt || {}));
    throw new Error('Apple 영수증에 구매 항목이 없습니다.');
  }

  // 가장 최근 구매 항목
  const latest = inApp[inApp.length - 1];
  console.log(`[IAP:Apple] 검증 성공 — productId: ${latest.product_id}, transactionId: ${latest.transaction_id}`);
  return {
    productId: latest.product_id,
    transactionId: latest.transaction_id,
    valid: true,
  };
}

async function callAppleVerify(url, receiptData) {
  const body = { 'receipt-data': receiptData };

  // 공유 시크릿이 있으면 추가 (자동 갱신 구독용이지만 안전을 위해)
  if (process.env.APPLE_SHARED_SECRET) {
    body.password = process.env.APPLE_SHARED_SECRET;
  }

  console.log(`[IAP:Apple] API 호출 → ${url}`);
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '(body read failed)');
    console.error(`[IAP:Apple] API HTTP 에러: ${response.status}, body: ${text.substring(0, 300)}`);
    throw new Error(`Apple API 호출 실패: ${response.status}`);
  }

  return response.json();
}

// ── Google Play 영수증 검증 ──

let androidPublisher = null;

function getAndroidPublisher() {
  if (androidPublisher) return androidPublisher;

  let keyFile;

  // 1) 환경변수 JSON
  if (process.env.GOOGLE_PLAY_SERVICE_ACCOUNT) {
    const key = JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT);
    const auth = new google.auth.GoogleAuth({
      credentials: key,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    androidPublisher = google.androidpublisher({ version: 'v3', auth });
    return androidPublisher;
  }

  // 2) 파일
  try {
    const __dirname = dirname(fileURLToPath(import.meta.url));
    keyFile = join(__dirname, '../../google-play-service-account.json');
    readFileSync(keyFile); // 존재 확인
  } catch {
    console.warn('[IAP] Google Play 서비스 계정 없음 — Android 검증 불가');
    return null;
  }

  const auth = new google.auth.GoogleAuth({
    keyFile,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  androidPublisher = google.androidpublisher({ version: 'v3', auth });
  return androidPublisher;
}

async function verifyGoogleReceipt(productId, purchaseToken) {
  console.log(`[IAP:Google] 영수증 검증 시작 — productId: ${productId}, token 길이: ${purchaseToken?.length || 0}`);
  const publisher = getAndroidPublisher();
  if (!publisher) {
    console.error('[IAP:Google] 서비스 계정 미설정. GOOGLE_PLAY_SERVICE_ACCOUNT 환경변수 또는 google-play-service-account.json 필요');
    throw new Error('Google Play 서비스 계정이 설정되지 않았습니다.');
  }

  console.log(`[IAP:Google] Play API 호출 — package: ${ANDROID_PACKAGE_NAME}, product: ${productId}`);
  const result = await publisher.purchases.products.get({
    packageName: ANDROID_PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });

  const purchase = result.data;
  console.log(`[IAP:Google] API 응답 — purchaseState: ${purchase.purchaseState}, consumptionState: ${purchase.consumptionState}, acknowledgementState: ${purchase.acknowledgementState}, orderId: ${purchase.orderId}`);

  // purchaseState: 0=구매완료, 1=취소됨
  if (purchase.purchaseState !== 0) {
    throw new Error(`Google 구매 상태 비정상: ${purchase.purchaseState}`);
  }

  console.log(`[IAP:Google] 검증 성공 — orderId: ${purchase.orderId}`);
  return {
    productId,
    orderId: purchase.orderId,
    valid: true,
  };
}

// ── 통합 검증 함수 ──

/**
 * 플랫폼별 영수증 검증
 * @param {string} platform - 'ios' | 'android'
 * @param {string} productId - 상품 ID
 * @param {string} purchaseToken - 영수증 데이터 (iOS: base64 receipt, Android: purchase token)
 * @returns {{ valid: boolean, productId: string }} 검증 결과
 */
export async function verifyPurchaseReceipt(platform, productId, purchaseToken) {
  console.log(`[IAP] ===== 영수증 검증 시작 =====`);
  console.log(`[IAP] platform: ${platform}, productId: ${productId}, token 길이: ${purchaseToken?.length || 0}`);

  if (platform === 'ios') {
    const result = await verifyAppleReceipt(purchaseToken);

    // 서버에서 받은 product_id와 클라이언트가 보낸 productId 일치 확인
    if (result.productId !== productId) {
      console.error(`[IAP] Product ID 불일치! 요청: ${productId}, 영수증: ${result.productId}`);
      throw new Error(`Product ID 불일치: 요청=${productId}, 영수증=${result.productId}`);
    }

    console.log(`[IAP] ===== iOS 검증 완료 =====`);
    return result;
  }

  if (platform === 'android') {
    const result = await verifyGoogleReceipt(productId, purchaseToken);
    console.log(`[IAP] ===== Android 검증 완료 =====`);
    return result;
  }

  throw new Error(`지원하지 않는 플랫폼: ${platform}`);
}
