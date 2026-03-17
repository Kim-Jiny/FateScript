import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';
import { getUserResults } from '../services/fortune.js';

const router = Router();

/**
 * POST /api/user/saju — 사주 저장/업데이트
 */
router.post('/saju', requireAuth, async (req, res) => {
  try {
    console.log(`[user/saju] POST uid=${req.uid} email=${req.userEmail} body=${JSON.stringify(req.body)}`);
    const { birthDate, birthTime, gender } = req.body ?? {};

    if (!birthDate || !gender) {
      console.log('[user/saju] Missing required fields');
      return res.status(400).json({ error: 'birthDate, gender는 필수입니다.' });
    }

    const result = await pool.query(
      `INSERT INTO users (uid, email, birth_date, birth_time, gender, updated_at)
       VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (uid) DO UPDATE
       SET email = $2, birth_date = $3, birth_time = $4, gender = $5, updated_at = now()`,
      [req.uid, req.userEmail, birthDate, birthTime ?? 'unknown', gender],
    );
    console.log(`[user/saju] DB result: rowCount=${result.rowCount}`);

    // 신규 유저에게 무료 티켓 3장 지급
    await pool.query(
      `INSERT INTO tickets (uid, balance) VALUES ($1, 3) ON CONFLICT DO NOTHING`,
      [req.uid],
    );

    res.json({ ok: true });
  } catch (err) {
    console.error('[user/saju] Save saju error:', err);
    res.status(500).json({ error: '사주 저장 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/user/saju — 저장된 사주 조회
 */
router.get('/saju', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT birth_date, birth_time, gender FROM users WHERE uid = $1',
      [req.uid],
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: '저장된 사주 정보가 없습니다.' });
    }

    const row = rows[0];
    res.json({
      birthDate: row.birth_date,
      birthTime: row.birth_time,
      gender: row.gender,
    });
  } catch (err) {
    console.error('Get saju error:', err);
    res.status(500).json({ error: '사주 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/user/my-results — 저장된 모든 결과 조회
 */
router.get('/my-results', requireAuth, async (req, res) => {
  try {
    const results = await getUserResults(req.uid);
    res.json({ results });
  } catch (err) {
    console.error('Get my results error:', err);
    res.status(500).json({ error: '저장된 결과 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * DELETE /api/user/account — 회원탈퇴 (모든 유저 데이터 삭제)
 */
router.delete('/account', requireAuth, async (req, res) => {
  try {
    const uid = req.uid;

    await pool.query('DELETE FROM ticket_transactions WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM tickets WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM compatibility_history WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM user_results WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM users WHERE uid = $1', [uid]);

    res.json({ ok: true });
  } catch (err) {
    console.error('Delete account error:', err);
    res.status(500).json({ error: '계정 삭제 중 오류가 발생했습니다.' });
  }
});

export default router;
