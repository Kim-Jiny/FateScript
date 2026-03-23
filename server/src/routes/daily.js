import { Router } from 'express';
import { getDailyFortune, saveUserResult } from '../services/fortune.js';
import { optionalAuth } from '../middleware/auth.js';
import { consumeTicketForService, refundTicketForService } from '../utils/ticket-consume.js';
import pool from '../config/db.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
  try {
    const { birthDate, birthTime, gender, clientDate, consumeTicket } = req.body ?? {};

    if (!birthDate || !gender) {
      return res.status(400).json({ error: 'birthDate와 gender는 필수입니다.' });
    }

    // 기존 결과 확인 (티켓 차감 전에 중복 방지)
    if (consumeTicket && req.uid) {
      const todayDate = clientDate || new Date().toISOString().slice(0, 10);
      const { rows: existing } = await pool.query(
        `SELECT result FROM user_results
         WHERE uid = $1 AND type = 'daily' AND date = $2
           AND params->>'birthDate' = $3 AND params->>'gender' = $4`,
        [req.uid, todayDate, birthDate, gender],
      );
      if (existing.length > 0) {
        return res.json(existing[0].result);
      }
    }

    // 티켓 차감 (요청 시)
    let ticketBalance;
    if (consumeTicket && req.uid) {
      const ticketResult = await consumeTicketForService(req.uid, 'daily');
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

      const result = await getDailyFortune({ year, month, day, hour, minute, gender, clientDate });

      // 로그인한 유저면 결과 저장
      if (req.uid) {
        try {
          const todayDate = clientDate || new Date().toISOString().slice(0, 10);
          await saveUserResult({
            uid: req.uid,
            type: 'daily',
            params: { birthDate, birthTime, gender },
            result,
            date: todayDate,
          });
        } catch (err) {
          console.error('Failed to save user daily result:', err);
        }
      }

      const response = { ...result };
      if (ticketBalance !== undefined) response._balance = ticketBalance;
      res.json(response);
    } catch (serviceErr) {
      if (consumeTicket && req.uid && ticketBalance !== undefined) {
        await refundTicketForService(req.uid, 'daily');
      }
      throw serviceErr;
    }
  } catch (err) {
    console.error('Daily fortune error:', err);
    res.status(500).json({ error: '오늘의 운세 조회 중 오류가 발생했습니다.' });
  }
});

export default router;
