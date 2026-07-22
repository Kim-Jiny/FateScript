import crypto from 'crypto';
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';
import { verifyPurchaseReceipt } from '../services/iap-verify.js';
import { TICKET_COST } from '../utils/ticket-consume.js';

const router = Router();

/** 앱의 obfuscatedAccountIdFor()와 동일한 계산 (SHA-256 hex) */
function obfuscatedAccountIdFor(uid) {
  return crypto.createHash('sha256').update(uid, 'utf8').digest('hex');
}

/**
 * GET /api/tickets/products — 활성 상품 목록 (인증 불필요)
 */
router.get('/products', async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT product_id, name, ticket_count, price_krw
       FROM iap_products
       WHERE is_active = true
       ORDER BY sort_order ASC, id ASC`,
    );
    res.json({ products: rows });
  } catch (err) {
    console.error('Get products error:', err);
    res.status(500).json({ error: '상품 목록 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/tickets/balance — 티켓 잔액 조회
 */
router.get('/balance', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT balance FROM tickets WHERE uid = $1',
      [req.uid],
    );
    res.json({ balance: rows.length > 0 ? rows[0].balance : 0 });
  } catch (err) {
    console.error('Get ticket balance error:', err);
    res.status(500).json({ error: '티켓 잔액 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/tickets/history — 티켓 사용 내역 (최신순 50건)
 */
router.get('/history', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, type, amount, balance_after, ref_id, created_at
       FROM ticket_transactions
       WHERE uid = $1
       ORDER BY created_at DESC
       LIMIT 50`,
      [req.uid],
    );
    res.json({ history: rows });
  } catch (err) {
    console.error('Get ticket history error:', err);
    res.status(500).json({ error: '티켓 내역 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * POST /api/tickets/consume — [DEPRECATED] 사전 차감 엔드포인트
 *
 * 티켓 차감은 이제 각 서비스 라우트(fortune, compatibility, name-analysis,
 * auspicious-date, team-compatibility)가 결과를 만들면서 직접 수행한다.
 * 여기서 차감하면 이미 배포된 구버전 앱이 이중으로 차감되므로,
 * 잔액 사전 확인(부족하면 402)만 하고 실제 차감은 하지 않는다.
 *
 * 구버전 앱이 사라지면 이 엔드포인트째로 삭제할 것.
 */
router.post('/consume', requireAuth, async (req, res) => {
  try {
    const { type } = req.body ?? {};
    if (!type) {
      return res.status(400).json({ error: 'type은 필수입니다.' });
    }

    const cost = TICKET_COST[type] ?? 1;

    const { rows } = await pool.query(
      'SELECT balance FROM tickets WHERE uid = $1',
      [req.uid],
    );
    const balance = rows.length > 0 ? rows[0].balance : 0;

    // 잔액 부족은 여기서 미리 걸러 구버전 앱의 '티켓 부족' 다이얼로그를 유지한다.
    if (balance < cost) {
      return res.status(402).json({ error: '티켓이 부족합니다.', balance, required: cost });
    }

    res.json({ balance });
  } catch (err) {
    console.error('Consume ticket precheck error:', err);
    res.status(500).json({ error: '티켓 확인 중 오류가 발생했습니다.' });
  }
});

/**
 * POST /api/tickets/verify-purchase — 인앱결제 영수증 검증 후 티켓 적립
 * body: { platform, productId, purchaseToken }
 */
router.post('/verify-purchase', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { platform, productId, purchaseToken } = req.body ?? {};

    console.log(`[IAP:verify-purchase] ===== 요청 수신 =====`);
    console.log(`[IAP:verify-purchase] uid: ${req.uid}`);
    console.log(`[IAP:verify-purchase] platform: ${platform}, productId: ${productId}`);
    console.log(`[IAP:verify-purchase] purchaseToken 존재: ${!!purchaseToken}, 길이: ${purchaseToken?.length || 0}`);

    if (!platform || !productId || !purchaseToken) {
      console.warn(`[IAP:verify-purchase] 필수 파라미터 누락 — platform: ${!!platform}, productId: ${!!productId}, purchaseToken: ${!!purchaseToken}`);
      return res.status(400).json({ error: 'platform, productId, purchaseToken은 필수입니다.' });
    }

    // 스토어 영수증 검증 (Apple/Google) — 트랜잭션 밖에서 수행
    console.log(`[IAP:verify-purchase] 스토어 영수증 검증 시작...`);
    let verifyResult;
    try {
      verifyResult = await verifyPurchaseReceipt(platform, productId, purchaseToken);
      console.log(`[IAP:verify-purchase] 영수증 검증 성공:`, JSON.stringify(verifyResult));
    } catch (verifyErr) {
      console.error(`[IAP:verify-purchase] 영수증 검증 실패 (${platform}):`, verifyErr.message);
      console.error(`[IAP:verify-purchase] 에러 스택:`, verifyErr.stack);
      return res.status(403).json({ error: '영수증 검증에 실패했습니다.' });
    }

    // 구매를 시작한 계정과 요청한 계정이 같은지 확인.
    // 구버전 앱은 obfuscatedAccountId를 보내지 않으므로 값이 있을 때만 검사한다.
    if (verifyResult.obfuscatedAccountId) {
      const expected = obfuscatedAccountIdFor(req.uid);
      if (verifyResult.obfuscatedAccountId !== expected) {
        console.error(`[IAP:verify-purchase] 계정 불일치! uid: ${req.uid}, 영수증 accountId: ${verifyResult.obfuscatedAccountId}`);
        return res.status(403).json({ error: '다른 계정에서 결제된 영수증입니다.' });
      }
      console.log('[IAP:verify-purchase] 계정 일치 확인 완료');
    } else {
      console.warn(`[IAP:verify-purchase] obfuscatedAccountId 없음 (구버전 앱 가능) — uid: ${req.uid}`);
    }

    // transactionId를 중복 체크 키로 사용 (StoreKit 2는 매번 다른 JWS를 생성하므로)
    const txnId = verifyResult.transactionId || verifyResult.orderId || purchaseToken;
    const environment = verifyResult.environment || 'Production';
    console.log(`[IAP:verify-purchase] 중복 체크 키 (txnId): ${txnId}, environment: ${environment}`);

    // 상품 ID → 티켓 수 DB 조회
    const { rows: productRows } = await pool.query(
      'SELECT ticket_count FROM iap_products WHERE product_id = $1',
      [productId],
    );
    console.log(`[IAP:verify-purchase] DB 상품 조회 — productId: ${productId}, 결과: ${productRows.length}건`);
    if (productRows.length === 0) {
      console.error(`[IAP:verify-purchase] DB에 상품 없음! productId: ${productId}`);
      return res.status(400).json({ error: '알 수 없는 상품 ID입니다.' });
    }
    const ticketCount = productRows[0].ticket_count;
    console.log(`[IAP:verify-purchase] 지급 티켓 수: ${ticketCount}`);

    await client.query('BEGIN');

    // advisory lock으로 동일 transactionId 동시 처리 방지
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [txnId]);

    // 중복 방지: 같은 transactionId로 이미 적립했는지 확인 (lock 내부에서)
    const { rows: existing } = await client.query(
      `SELECT id FROM ticket_transactions WHERE ref_id = $1 AND type = 'purchase'`,
      [txnId],
    );
    if (existing.length > 0) {
      await client.query('ROLLBACK');
      console.log(`[IAP:verify-purchase] 중복 요청 — 이미 처리된 txnId: ${txnId}`);
      const { rows } = await client.query(
        'SELECT balance FROM tickets WHERE uid = $1',
        [req.uid],
      );
      return res.json({ balance: rows[0]?.balance ?? 0, duplicate: true });
    }

    // 잔액 증가
    await client.query(
      `INSERT INTO tickets (uid, balance, updated_at)
       VALUES ($1, $2, now())
       ON CONFLICT (uid) DO UPDATE
       SET balance = tickets.balance + $2, updated_at = now()`,
      [req.uid, ticketCount],
    );

    const { rows } = await client.query(
      'SELECT balance FROM tickets WHERE uid = $1',
      [req.uid],
    );

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id, platform, product_id, environment)
       VALUES ($1, 'purchase', $2, $3, $4, $5, $6, $7)`,
      [req.uid, ticketCount, rows[0].balance, txnId, platform, productId, environment],
    );

    await client.query('COMMIT');
    console.log(`[IAP:verify-purchase] 성공! uid: ${req.uid}, +${ticketCount}장, 잔액: ${rows[0].balance}`);
    res.json({ balance: rows[0].balance });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[IAP:verify-purchase] 예외 발생:', err.message);
    console.error('[IAP:verify-purchase] 스택:', err.stack);
    res.status(500).json({ error: '구매 검증 중 오류가 발생했습니다.' });
  } finally {
    client.release();
  }
});

// POST /api/tickets/restore-purchases 는 제거되었다.
// 중복 체크 키가 verify-purchase(transactionId/orderId)와 달리 purchaseToken이라
// 같은 구매가 두 번 지급됐고, 트랜잭션·advisory lock도 없었다.
// 앱에서 호출하는 곳이 없으므로 복원이 필요해지면 verify-purchase 경로를 재사용할 것.

export default router;
