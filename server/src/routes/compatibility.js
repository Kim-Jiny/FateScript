import { Router } from 'express';
import { getCompatibility, saveCompatibilityHistory, getCompatibilityHistory, deleteCompatibilityHistory } from '../services/fortune.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';

const router = Router();

router.post('/', optionalAuth, async (req, res) => {
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

    res.json(result);
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
