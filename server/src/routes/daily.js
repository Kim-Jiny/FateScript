import { Router } from 'express';
import { getDailyFortune, saveUserResult } from '../services/fortune.js';
import { optionalAuth } from '../middleware/auth.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
  try {
    const { birthDate, birthTime, gender, clientDate } = req.body ?? {};

    if (!birthDate || !gender) {
      return res.status(400).json({ error: 'birthDate와 gender는 필수입니다.' });
    }

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

    res.json(result);
  } catch (err) {
    console.error('Daily fortune error:', err);
    res.status(500).json({ error: '오늘의 운세 조회 중 오류가 발생했습니다.' });
  }
});

export default router;
