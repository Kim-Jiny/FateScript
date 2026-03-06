import { Router } from 'express';
import { getCompatibility } from '../services/fortune.js';

const router = Router();

router.post('/', async (req, res) => {
  try {
    const {
      myBirthDate, myBirthTime, myGender,
      partnerBirthDate, partnerBirthTime, partnerGender,
      relationship,
    } = req.body ?? {};

    if (!myBirthDate || !myGender || !partnerBirthDate || !partnerGender || !relationship) {
      return res.status(400).json({ error: '필수 항목이 누락되었습니다.' });
    }

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
    res.json(result);
  } catch (err) {
    console.error('Compatibility error:', err);
    res.status(500).json({ error: '궁합 분석 중 오류가 발생했습니다.' });
  }
});

export default router;
