import { Router } from 'express';
import { analyzeNameFortune, recommendNames } from '../services/fortune.js';

const router = Router();

router.post('/', async (req, res) => {
  try {
    const { mode, name, lastName, birthDate, birthTime, gender } = req.body ?? {};

    if (!mode || !birthDate || !gender) {
      return res.status(400).json({ error: 'mode, birthDate, gender는 필수입니다.' });
    }

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
      return res.json(result);
    }

    if (mode === 'recommend') {
      if (!lastName) {
        return res.status(400).json({ error: '이름 추천 모드에서는 lastName이 필수입니다.' });
      }
      const result = await recommendNames({ year, month, day, hour, minute, gender, lastName });
      return res.json(result);
    }

    return res.status(400).json({ error: 'mode는 analyze 또는 recommend여야 합니다.' });
  } catch (err) {
    console.error('Name analysis error:', err);
    res.status(500).json({ error: '성명학 분석 중 오류가 발생했습니다.' });
  }
});

export default router;
