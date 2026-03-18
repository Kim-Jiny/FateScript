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
  // Production 먼저 시도, 21007이면 Sandbox로 재시도
  let result = await callAppleVerify(APPLE_VERIFY_PRODUCTION, receiptData);

  if (result.status === 21007) {
    // Sandbox 영수증 → Sandbox 서버로 재시도
    result = await callAppleVerify(APPLE_VERIFY_SANDBOX, receiptData);
  }

  if (result.status !== 0) {
    throw new Error(`Apple 영수증 검증 실패 (status: ${result.status})`);
  }

  // bundle_id 확인
  const bundleId = result.receipt?.bundle_id;
  if (bundleId !== IOS_BUNDLE_ID) {
    throw new Error(`Bundle ID 불일치: ${bundleId}`);
  }

  // in_app 항목에서 product_id 추출
  const inApp = result.receipt?.in_app ?? result.latest_receipt_info ?? [];
  if (inApp.length === 0) {
    throw new Error('Apple 영수증에 구매 항목이 없습니다.');
  }

  // 가장 최근 구매 항목
  const latest = inApp[inApp.length - 1];
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

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
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
  const publisher = getAndroidPublisher();
  if (!publisher) {
    throw new Error('Google Play 서비스 계정이 설정되지 않았습니다.');
  }

  const result = await publisher.purchases.products.get({
    packageName: ANDROID_PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });

  const purchase = result.data;

  // purchaseState: 0=구매완료, 1=취소됨
  if (purchase.purchaseState !== 0) {
    throw new Error(`Google 구매 상태 비정상: ${purchase.purchaseState}`);
  }

  // consumptionState: 0=미소비, 1=소비됨
  // acknowledgementState: 0=미확인, 1=확인됨
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
  if (platform === 'ios') {
    const result = await verifyAppleReceipt(purchaseToken);

    // 서버에서 받은 product_id와 클라이언트가 보낸 productId 일치 확인
    if (result.productId !== productId) {
      throw new Error(`Product ID 불일치: 요청=${productId}, 영수증=${result.productId}`);
    }

    return result;
  }

  if (platform === 'android') {
    return await verifyGoogleReceipt(productId, purchaseToken);
  }

  throw new Error(`지원하지 않는 플랫폼: ${platform}`);
}
