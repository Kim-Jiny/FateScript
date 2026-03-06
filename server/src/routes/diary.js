import { Router } from 'express';
import { consultDiary } from '../services/fortune.js';

const router = Router();

router.post('/', async (req, res) => {
  try {
    const { birthDate, birthTime, gender, diaryText } = req.body ?? {};

    if (!birthDate || !gender || !diaryText) {
      return res.status(400).json({ error: 'birthDate, gender, diaryText는 필수입니다.' });
    }

    const [year, month, day] = birthDate.split('-').map(Number);
    let hour = null;
    let minute = null;

    if (birthTime && birthTime !== 'unknown') {
      const parts = birthTime.split(':').map(Number);
      hour = parts[0];
      minute = parts[1] ?? 0;
    }

    const result = await consultDiary({ year, month, day, hour, minute, gender, diaryText });
    res.json(result);
  } catch (err) {
    console.error('Diary error:', err);
    res.status(500).json({ error: '일기 상담 중 오류가 발생했습니다.' });
  }
});

export default router;
