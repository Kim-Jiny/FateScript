import { Router } from 'express';
import { interpretFortune, saveUserResult } from '../services/fortune.js';
import { optionalAuth } from '../middleware/auth.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
  try {
    const { birthDate, birthTime, gender } = req.body ?? {};

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

    const result = await interpretFortune({ year, month, day, hour, minute, gender });

    // 로그인한 유저면 결과 저장
    if (req.uid) {
      try {
        await saveUserResult({
          uid: req.uid,
          type: 'fortune',
          params: { birthDate, birthTime, gender },
          result,
          year: new Date().getFullYear(),
        });
      } catch (err) {
        console.error('Failed to save user fortune result:', err);
      }
    }

    res.json(result);
  } catch (err) {
    console.error('Fortune error:', err);
    res.status(500).json({ error: '사주 해석 중 오류가 발생했습니다.' });
  }
});

export default router;
