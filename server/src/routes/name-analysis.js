import { Router } from 'express';
import { analyzeNameFortune, recommendNames, saveUserResult, saveNameHistory, getNameHistory, deleteNameHistory } from '../services/fortune.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { consumeTicketForService, refundTicketForService } from '../utils/ticket-consume.js';
import pool from '../config/db.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
  try {
    const { mode, name, lastName, birthDate, birthTime, gender, consumeTicket } = req.body ?? {};

    if (!mode || !birthDate || !gender) {
      return res.status(400).json({ error: 'mode, birthDate, gender는 필수입니다.' });
    }

    if (mode !== 'analyze' && mode !== 'recommend') {
      return res.status(400).json({ error: 'mode는 analyze 또는 recommend여야 합니다.' });
    }

    const ticketType = mode === 'analyze' ? 'name_analyze' : 'name_recommend';

    // 기존 결과 확인 (티켓 차감 전에 중복 방지)
    if (consumeTicket && req.uid) {
      const { rows: existing } = await pool.query(
        `SELECT result FROM name_history
         WHERE uid = $1 AND mode = $2
           AND birth_date = $3 AND gender = $4
           AND ($5::text IS NULL OR name = $5)
           AND ($6::text IS NULL OR last_name = $6)
         ORDER BY created_at DESC LIMIT 1`,
        [req.uid, mode, birthDate, gender, mode === 'analyze' ? name : null, mode === 'recommend' ? lastName : null],
      );
      if (existing.length > 0) {
        return res.json(existing[0].result);
      }
    }

    // 티켓 차감 (요청 시)
    let ticketBalance;
    if (consumeTicket && req.uid) {
      const ticketResult = await consumeTicketForService(req.uid, ticketType);
      if (!ticketResult.success) {
        return res.status(402).json({ error: '티켓이 부족합니다.', balance: ticketResult.balance, required: ticketResult.required });
      }
      ticketBalance = ticketResult.balance;
    }

    try {
      const [year, month, day] = birthDate.split('-').map(Number);
      let hour = null;
      let minute = null;

      if (birthTime && birthTime !== 'unknown') {
        const parts = birthTime.split(':').map(Number);
        hour = parts[0];
        minute = parts[1] ?? 0;
      }

      if (mode === 'analyze') {
        if (!name) {
          return res.status(400).json({ error: '이름 분석 모드에서는 name이 필수입니다.' });
        }
        const result = await analyzeNameFortune({ year, month, day, hour, minute, gender, name });

        if (req.uid) {
          try {
            await saveUserResult({
              uid: req.uid,
              type: 'name_analyze',
              params: { name, birthDate, birthTime, gender },
              result,
            });
            await saveNameHistory({
              uid: req.uid, mode: 'analyze', name, lastName: null,
              birthDate, birthTime, gender, result,
            });
          } catch (err) {
            console.error('Failed to save user name analysis result:', err);
          }
        }

        const response = { ...result };
        if (ticketBalance !== undefined) response._balance = ticketBalance;
        return res.json(response);
      }

      // mode === 'recommend'
      if (!lastName) {
        return res.status(400).json({ error: '이름 추천 모드에서는 lastName이 필수입니다.' });
      }
      const result = await recommendNames({ year, month, day, hour, minute, gender, lastName });

      if (req.uid) {
        try {
          await saveUserResult({
            uid: req.uid,
            type: 'name_recommend',
            params: { lastName, birthDate, birthTime, gender },
            result,
          });
          await saveNameHistory({
            uid: req.uid, mode: 'recommend', name: null, lastName,
            birthDate, birthTime, gender, result,
          });
        } catch (err) {
          console.error('Failed to save user name recommend result:', err);
        }
      }

      const response = { ...result };
      if (ticketBalance !== undefined) response._balance = ticketBalance;
      return res.json(response);
    } catch (serviceErr) {
      if (consumeTicket && req.uid && ticketBalance !== undefined) {
        await refundTicketForService(req.uid, ticketType);
      }
      throw serviceErr;
    }
  } catch (err) {
    console.error('Name analysis error:', err);
    res.status(500).json({ error: '성명학 분석 중 오류가 발생했습니다.' });
  }
});

// ── 히스토리 API ──

router.get('/history', requireAuth, async (req, res) => {
  try {
    const history = await getNameHistory(req.uid);
    res.json(history);
  } catch (err) {
    console.error('Get name history error:', err);
    res.status(500).json({ error: '성명학 히스토리 조회 중 오류가 발생했습니다.' });
  }
});

router.delete('/history/:id', requireAuth, async (req, res) => {
  try {
    await deleteNameHistory(req.uid, Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    console.error('Delete name history error:', err);
    res.status(500).json({ error: '성명학 히스토리 삭제 중 오류가 발생했습니다.' });
  }
});

export default router;
