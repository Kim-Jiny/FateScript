import { Router } from 'express';
import { getGapja } from '@fullstackfamily/manseryeok';
import { requireAuth } from '../middleware/auth.js';
import { getSajuInfo } from '../services/saju.js';
import { calculateMonthScore, analyzeOhengFromGapja } from '../utils/oheng.js';
import ai from '../config/gemini.js';
import pool from '../config/db.js';
import { getSystemPrompt } from '../prompts/system.js';
import { buildAuspiciousDatePrompt } from '../prompts/system.js';

const router = Router();
const MODEL = 'gemini-2.5-flash';

/**
 * POST /api/auspicious-date
 * body: { birthDate, birthTime, gender, eventType, startDate, endDate }
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const { birthDate, birthTime, gender, eventType, startDate, endDate } = req.body ?? {};

    if (!birthDate || !gender || !eventType || !startDate || !endDate) {
      return res.status(400).json({ error: 'birthDate, gender, eventType, startDate, endDate는 필수입니다.' });
    }

    // 캐시 확인
    const cacheKey = `auspicious:${birthDate}-${birthTime}-${gender}:${eventType}:${startDate}:${endDate}`;
    const { rows: cached } = await pool.query(
      'SELECT result FROM auspicious_date_cache WHERE cache_key = $1',
      [cacheKey],
    );
    if (cached.length > 0) {
      return res.json(cached[0].result);
    }

    const [year, month, day] = birthDate.split('-').map(Number);
    let hour = null, minute = null;
    if (birthTime && birthTime !== 'unknown') {
      const parts = birthTime.split(':').map(Number);
      hour = parts[0];
      minute = parts[1] ?? 0;
    }

    const sajuInfo = getSajuInfo(year, month, day, hour, minute);
    const userOheng = sajuInfo.oheng;

    // 날짜 범위 내 각 날짜의 점수 계산
    const start = new Date(startDate);
    const end = new Date(endDate);
    const dayScores = [];

    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const y = d.getFullYear();
      const m = d.getMonth() + 1;
      const dd = d.getDate();

      const gapja = getGapja(y, m, dd);
      const dayOheng = analyzeOhengFromGapja(gapja);
      const score = calculateMonthScore(userOheng.distribution, dayOheng.distribution);

      dayScores.push({
        date: `${y}-${String(m).padStart(2, '0')}-${String(dd).padStart(2, '0')}`,
        pillar: gapja.dayPillar,
        pillarHanja: gapja.dayPillarHanja,
        score,
        oheng: dayOheng,
      });
    }

    // Top 5 선정
    dayScores.sort((a, b) => b.score - a.score);
    const top5 = dayScores.slice(0, 5);

    // AI 설명 요청
    const prompt = buildAuspiciousDatePrompt(sajuInfo, top5, eventType);
    const response = await ai.models.generateContent({
      model: MODEL,
      contents: prompt,
      config: {
        systemInstruction: getSystemPrompt('date'),
        maxOutputTokens: 8192,
        temperature: 0.8,
      },
    });
    const advice = response.text;

    const result = {
      dates: top5.map(d => ({
        date: d.date,
        pillar: `${d.pillar} (${d.pillarHanja})`,
        score: d.score,
        reason: '',
      })),
      advice,
    };

    // AI 응답에서 각 날짜별 이유 추출 시도 (간단히 advice에 통합)
    // 캐시 저장
    await pool.query(
      'INSERT INTO auspicious_date_cache (cache_key, result) VALUES ($1, $2) ON CONFLICT (cache_key) DO NOTHING',
      [cacheKey, JSON.stringify(result)],
    );

    res.json(result);
  } catch (err) {
    console.error('Auspicious date error:', err);
    res.status(500).json({ error: '택일 분석 중 오류가 발생했습니다.' });
  }
});

export default router;
