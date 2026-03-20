import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';
import { verifyPurchaseReceipt } from '../services/iap-verify.js';

const router = Router();

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
 * POST /api/tickets/consume — 서비스별 티켓 소모
 * body: { type } — fortune type (daily, fortune, name_analyze, name_recommend, compatibility)
 */
const TICKET_COST = {
  daily: 1,
  fortune: 3,
  name_analyze: 1,
  name_recommend: 2,
  compatibility: 2,
  auspicious_date: 2,
  team_compatibility: 3,
};

router.post('/consume', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { type } = req.body ?? {};
    if (!type) {
      return res.status(400).json({ error: 'type은 필수입니다.' });
    }

    const cost = TICKET_COST[type] ?? 1;

    await client.query('BEGIN');

    const { rows } = await client.query(
      'SELECT balance FROM tickets WHERE uid = $1 FOR UPDATE',
      [req.uid],
    );

    const currentBalance = rows.length > 0 ? rows[0].balance : 0;

    if (currentBalance < cost) {
      await client.query('ROLLBACK');
      return res.status(402).json({ error: '티켓이 부족합니다.', balance: currentBalance, required: cost });
    }

    const newBalance = currentBalance - cost;

    await client.query(
      `UPDATE tickets SET balance = $1, updated_at = now() WHERE uid = $2`,
      [newBalance, req.uid],
    );

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
       VALUES ($1, 'consume', $2, $3, $4)`,
      [req.uid, -cost, newBalance, type],
    );

    await client.query('COMMIT');
    res.json({ balance: newBalance });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Consume ticket error:', err);
    res.status(500).json({ error: '티켓 소모 중 오류가 발생했습니다.' });
  } finally {
    client.release();
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

    if (!platform || !productId || !purchaseToken) {
      return res.status(400).json({ error: 'platform, productId, purchaseToken은 필수입니다.' });
    }

    // 중복 방지: 같은 purchaseToken으로 이미 적립했는지 확인
    const { rows: existing } = await client.query(
      `SELECT id FROM ticket_transactions WHERE ref_id = $1 AND type = 'purchase'`,
      [purchaseToken],
    );
    if (existing.length > 0) {
      // 이미 처리됨 — 멱등성 보장을 위해 현재 잔액 반환
      const { rows } = await client.query(
        'SELECT balance FROM tickets WHERE uid = $1',
        [req.uid],
      );
      return res.json({ balance: rows[0]?.balance ?? 0, duplicate: true });
    }

    // 스토어 영수증 검증 (Apple/Google)
    try {
      await verifyPurchaseReceipt(platform, productId, purchaseToken);
    } catch (verifyErr) {
      console.error(`[IAP] Receipt verification failed (${platform}):`, verifyErr.message);
      return res.status(403).json({ error: '영수증 검증에 실패했습니다.', detail: verifyErr.message });
    }

    // 상품 ID → 티켓 수 DB 조회
    const { rows: productRows } = await pool.query(
      'SELECT ticket_count FROM iap_products WHERE product_id = $1',
      [productId],
    );
    if (productRows.length === 0) {
      return res.status(400).json({ error: '알 수 없는 상품 ID입니다.' });
    }
    const ticketCount = productRows[0].ticket_count;

    await client.query('BEGIN');

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
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
       VALUES ($1, 'purchase', $2, $3, $4)`,
      [req.uid, ticketCount, rows[0].balance, purchaseToken],
    );

    await client.query('COMMIT');
    res.json({ balance: rows[0].balance });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Verify purchase error:', err);
    res.status(500).json({ error: '구매 검증 중 오류가 발생했습니다.' });
  } finally {
    client.release();
  }
});

/**
 * POST /api/tickets/restore-purchases — iOS 구매 복원
 */
router.post('/restore-purchases', requireAuth, async (req, res) => {
  try {
    // 복원 시 클라이언트가 보내는 과거 구매 목록 처리
    const { purchases } = req.body ?? {};
    if (!Array.isArray(purchases)) {
      return res.status(400).json({ error: 'purchases 배열이 필요합니다.' });
    }

    let restoredCount = 0;
    for (const p of purchases) {
      const { productId, purchaseToken, platform } = p;
      if (!productId || !purchaseToken) continue;

      // 이미 처리된 것은 스킵
      const { rows: existing } = await pool.query(
        `SELECT id FROM ticket_transactions WHERE ref_id = $1 AND type = 'purchase'`,
        [purchaseToken],
      );
      if (existing.length > 0) continue;

      // 영수증 검증
      try {
        await verifyPurchaseReceipt(platform || 'ios', productId, purchaseToken);
      } catch (verifyErr) {
        console.warn(`[IAP] Restore verification failed for ${productId}:`, verifyErr.message);
        continue;
      }

      const { rows: productRows } = await pool.query(
        'SELECT ticket_count FROM iap_products WHERE product_id = $1',
        [productId],
      );
      if (productRows.length === 0) continue;
      const ticketCount = productRows[0].ticket_count;

      await pool.query(
        `INSERT INTO tickets (uid, balance, updated_at)
         VALUES ($1, $2, now())
         ON CONFLICT (uid) DO UPDATE
         SET balance = tickets.balance + $2, updated_at = now()`,
        [req.uid, ticketCount],
      );

      const { rows } = await pool.query(
        'SELECT balance FROM tickets WHERE uid = $1',
        [req.uid],
      );

      await pool.query(
        `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
         VALUES ($1, 'purchase', $2, $3, $4)`,
        [req.uid, ticketCount, rows[0].balance, purchaseToken],
      );

      restoredCount++;
    }

    const { rows } = await pool.query(
      'SELECT balance FROM tickets WHERE uid = $1',
      [req.uid],
    );

    res.json({ balance: rows[0]?.balance ?? 0, restoredCount });
  } catch (err) {
    console.error('Restore purchases error:', err);
    res.status(500).json({ error: '구매 복원 중 오류가 발생했습니다.' });
  }
});

export default router;
