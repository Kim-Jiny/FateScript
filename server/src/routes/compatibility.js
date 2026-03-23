import { Router } from 'express';
import { getCompatibility, saveCompatibilityHistory, getCompatibilityHistory, deleteCompatibilityHistory } from '../services/fortune.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { consumeTicketForService, refundTicketForService } from '../utils/ticket-consume.js';
import pool from '../config/db.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
  try {
    const {
      myBirthDate, myBirthTime, myGender,
      partnerBirthDate, partnerBirthTime, partnerGender,
      relationship, consumeTicket,
    } = req.body ?? {};

    if (!myBirthDate || !myGender || !partnerBirthDate || !partnerGender || !relationship) {
      return res.status(400).json({ error: '필수 항목이 누락되었습니다.' });
    }

    // 기존 결과 확인 (티켓 차감 전에 중복 방지)
    if (consumeTicket && req.uid) {
      const { rows: existing } = await pool.query(
        `SELECT result FROM compatibility_history
         WHERE uid = $1
           AND my_birth_date = $2 AND my_gender = $3
           AND partner_birth_date = $4 AND partner_gender = $5
           AND relationship = $6
         ORDER BY created_at DESC LIMIT 1`,
        [req.uid, myBirthDate, myGender, partnerBirthDate, partnerGender, relationship],
      );
      if (existing.length > 0) {
        return res.json(existing[0].result);
      }
    }

    // 티켓 차감 (요청 시)
    let ticketBalance;
    if (consumeTicket && req.uid) {
      const ticketResult = await consumeTicketForService(req.uid, 'compatibility');
      if (!ticketResult.success) {
        return res.status(402).json({ error: '티켓이 부족합니다.', balance: ticketResult.balance, required: ticketResult.required });
      }
      ticketBalance = ticketResult.balance;
    }

    try {
      function parsePerson(birthDate, birthTime, gender) {
        const [year, month, day] = birthDate.split('-').map(Number);
        let hour = null;
        let minute = null;

        if (birthTime && birthTime !== 'unknown') {
          const parts = birthTime.split(':').map(Number);
          hour = parts[0];
          minute = parts[1] ?? 0;
        }

        return { year, month, day, hour, minute, gender };
      }

      const my = parsePerson(myBirthDate, myBirthTime, myGender);
      const partner = parsePerson(partnerBirthDate, partnerBirthTime, partnerGender);

      const result = await getCompatibility({ my, partner, relationship });

      // 로그인한 유저면 히스토리에 자동 저장
      if (req.uid) {
        try {
          await saveCompatibilityHistory({
            uid: req.uid,
            myBirthDate, myBirthTime, myGender,
            partnerBirthDate, partnerBirthTime, partnerGender,
            relationship,
            result,
          });
        } catch (err) {
          console.error('Failed to save compatibility history:', err);
        }
      }

      const response = { ...result };
      if (ticketBalance !== undefined) response._balance = ticketBalance;
      res.json(response);
    } catch (serviceErr) {
      if (consumeTicket && req.uid && ticketBalance !== undefined) {
        await refundTicketForService(req.uid, 'compatibility');
      }
      throw serviceErr;
    }
  } catch (err) {
    console.error('Compatibility error:', err);
    res.status(500).json({ error: '궁합 분석 중 오류가 발생했습니다.' });
  }
});

router.get('/history', requireAuth, async (req, res) => {
  try {
    const history = await getCompatibilityHistory(req.uid);
    res.json(history);
  } catch (err) {
    console.error('Compatibility history error:', err);
    res.status(500).json({ error: '궁합 히스토리 조회 중 오류가 발생했습니다.' });
  }
});

router.delete('/history/:id', requireAuth, async (req, res) => {
  try {
    await deleteCompatibilityHistory(req.uid, Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    console.error('Compatibility history delete error:', err);
    res.status(500).json({ error: '궁합 히스토리 삭제 중 오류가 발생했습니다.' });
  }
});

export default router;
