import { Router } from 'express';
import { getGapja } from '@fullstackfamily/manseryeok';
import { getSajuInfo } from '../services/saju.js';
import { calculateMonthScore, analyzeOhengFromGapja } from '../utils/oheng.js';

const router = Router();

/**
 * POST /api/fortune-trend
 * body: { birthDate, birthTime, gender }
 * 12개월 운세 트렌드 — AI 호출 없음, 티켓 소모 없음
 */
router.post('/', (req, res) => {
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

    const sajuInfo = getSajuInfo(year, month, day, hour, minute);
    const userOheng = sajuInfo.oheng;

    const currentYear = new Date().getFullYear();
    const months = [];

    for (let m = 1; m <= 12; m++) {
      // 각 월의 15일 기준으로 월주 계산
      const gapja = getGapja(currentYear, m, 15);
      const monthOheng = analyzeOhengFromGapja(gapja);
      const score = calculateMonthScore(userOheng.distribution, monthOheng.distribution);

      // 해당 월의 주요 오행 찾기
      const dist = monthOheng.distribution;
      const dominant = Object.entries(dist).sort(([, a], [, b]) => b - a)[0]?.[0] ?? '토';

      months.push({
        month: m,
        pillar: gapja.monthPillar,
        score,
        dominantElement: dominant,
      });
    }

    res.json({ months });
  } catch (err) {
    console.error('Fortune trend error:', err);
    res.status(500).json({ error: '운세 트렌드 계산 중 오류가 발생했습니다.' });
  }
});

export default router;
