import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';

const router = Router();

/**
 * POST /api/user/saju — 사주 저장/업데이트
 */
router.post('/saju', requireAuth, async (req, res) => {
  try {
    const { birthDate, birthTime, gender } = req.body ?? {};

    if (!birthDate || !gender) {
      return res.status(400).json({ error: 'birthDate, gender는 필수입니다.' });
    }

    await pool.query(
      `INSERT INTO users (uid, email, birth_date, birth_time, gender, updated_at)
       VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (uid) DO UPDATE
       SET email = $2, birth_date = $3, birth_time = $4, gender = $5, updated_at = now()`,
      [req.uid, req.userEmail, birthDate, birthTime ?? 'unknown', gender],
    );

    res.json({ ok: true });
  } catch (err) {
    console.error('Save saju error:', err);
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

export default router;
