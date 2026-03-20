import { Router } from 'express';
import { getGapja, solarToLunar } from '@fullstackfamily/manseryeok';
import { analyzeOhengFromGapja } from '../utils/oheng.js';

const router = Router();

/**
 * GET /api/manseryeok?date=2026-03-20
 * 만세력 탐색 — AI 호출 없음, 티켓 소모 없음
 */
router.get('/', (req, res) => {
  try {
    const { date } = req.query;
    if (!date) {
      return res.status(400).json({ error: 'date 쿼리 파라미터는 필수입니다. (YYYY-MM-DD)' });
    }

    const [year, month, day] = date.split('-').map(Number);
    if (!year || !month || !day) {
      return res.status(400).json({ error: '유효하지 않은 날짜 형식입니다.' });
    }

    const gapja = getGapja(year, month, day);
    const lunar = solarToLunar(year, month, day);
    const oheng = analyzeOhengFromGapja(gapja);

    res.json({
      date,
      saju: {
        yearPillar: { hangul: gapja.yearPillar, hanja: gapja.yearPillarHanja },
        monthPillar: { hangul: gapja.monthPillar, hanja: gapja.monthPillarHanja },
        dayPillar: { hangul: gapja.dayPillar, hanja: gapja.dayPillarHanja },
      },
      lunar: {
        year: lunar.lunar.year,
        month: lunar.lunar.month,
        day: lunar.lunar.day,
        isLeapMonth: lunar.lunar.isLeapMonth,
      },
      oheng,
    });
  } catch (err) {
    console.error('Manseryeok error:', err);
    res.status(500).json({ error: '만세력 조회 중 오류가 발생했습니다.' });
  }
});

export default router;
