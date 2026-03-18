import crypto from 'crypto';
import { Router } from 'express';
import pool from '../config/db.js';

const router = Router();

// POST /api/share — 결과 공유 URL 생성
router.post('/', async (req, res) => {
  try {
    const { type, data, birthDate, birthTime, gender } = req.body;

    if (!type || !data) {
      return res.status(400).json({ error: 'type과 data는 필수입니다.' });
    }

    // ID 충돌 시 재시도
    let id;
    for (let i = 0; i < 5; i++) {
      id = crypto.randomBytes(4).toString('hex');
      try {
        await pool.query(
          `INSERT INTO shared_results (id, type, data, birth_date, birth_time, gender)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [id, type, JSON.stringify(data), birthDate || null, birthTime || null, gender || null],
        );
        break;
      } catch (err) {
        if (err.code === '23505' && i < 4) continue; // unique_violation → retry
        throw err;
      }
    }

    const shareUrl = `https://fate.jiny.shop/s/${id}`;
    res.json({ shareUrl });
  } catch (err) {
    console.error('share create error:', err);
    res.status(500).json({ error: '공유 URL 생성에 실패했습니다.' });
  }
});

export default router;
