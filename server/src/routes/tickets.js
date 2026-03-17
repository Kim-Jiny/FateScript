import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';

const router = Router();

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
 * POST /api/tickets/consume — 티켓 1장 소모
 * body: { type } — fortune type (daily, fortune, name, compatibility)
 */
router.post('/consume', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { type } = req.body ?? {};
    if (!type) {
      return res.status(400).json({ error: 'type은 필수입니다.' });
    }

    await client.query('BEGIN');

    const { rows } = await client.query(
      'SELECT balance FROM tickets WHERE uid = $1 FOR UPDATE',
      [req.uid],
    );

    const currentBalance = rows.length > 0 ? rows[0].balance : 0;

    if (currentBalance < 1) {
      await client.query('ROLLBACK');
      return res.status(402).json({ error: '티켓이 부족합니다.', balance: 0 });
    }

    const newBalance = currentBalance - 1;

    await client.query(
      `UPDATE tickets SET balance = $1, updated_at = now() WHERE uid = $2`,
      [newBalance, req.uid],
    );

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
       VALUES ($1, 'consume', -1, $2, $3)`,
      [req.uid, newBalance, type],
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

    // 상품 ID → 티켓 수 매핑
    const ticketMap = {
      saju_ticket_3: 3,
      saju_ticket_10: 10,
      saju_ticket_30: 30,
    };
    const ticketCount = ticketMap[productId];
    if (!ticketCount) {
      return res.status(400).json({ error: '알 수 없는 상품 ID입니다.' });
    }

    // TODO: 실제 스토어 영수증 검증 (Apple/Google) 추가
    // 현재는 클라이언트 신뢰 기반으로 처리

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
      const { productId, purchaseToken } = p;
      if (!productId || !purchaseToken) continue;

      // 이미 처리된 것은 스킵
      const { rows: existing } = await pool.query(
        `SELECT id FROM ticket_transactions WHERE ref_id = $1 AND type = 'purchase'`,
        [purchaseToken],
      );
      if (existing.length > 0) continue;

      const ticketMap = {
        saju_ticket_3: 3,
        saju_ticket_10: 10,
        saju_ticket_30: 30,
      };
      const ticketCount = ticketMap[productId];
      if (!ticketCount) continue;

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
