import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { getSajuInfo } from '../services/saju.js';
import ai from '../config/gemini.js';
import pool from '../config/db.js';
import { getSystemPrompt, buildTeamCompatibilityPrompt } from '../prompts/system.js';

const router = Router();
const MODEL = 'gemini-2.5-flash';

/**
 * POST /api/team-compatibility
 * body: { members: [{name?, birthDate, birthTime, gender}], relationship }
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const { members, relationship } = req.body ?? {};

    if (!Array.isArray(members) || members.length < 3 || members.length > 6) {
      return res.status(400).json({ error: '멤버는 3~6명이어야 합니다.' });
    }

    if (!relationship) {
      return res.status(400).json({ error: 'relationship은 필수입니다.' });
    }

    // 캐시 키 생성
    const memberKey = members
      .map(m => `${m.birthDate}-${m.birthTime || 'unknown'}-${m.gender}`)
      .sort()
      .join('|');
    const currentYear = new Date().getFullYear();
    const cacheKey = `team-compat:${memberKey}:${relationship}:${currentYear}`;

    const { rows: cached } = await pool.query(
      'SELECT result FROM team_compatibility_cache WHERE cache_key = $1',
      [cacheKey],
    );
    if (cached.length > 0) {
      return res.json(cached[0].result);
    }

    // 각 멤버의 사주 계산
    const memberSajuList = members.map((member, idx) => {
      const [year, month, day] = member.birthDate.split('-').map(Number);
      let hour = null, minute = null;
      if (member.birthTime && member.birthTime !== 'unknown') {
        const parts = member.birthTime.split(':').map(Number);
        hour = parts[0];
        minute = parts[1] ?? 0;
      }
      const sajuInfo = getSajuInfo(year, month, day, hour, minute);
      return {
        name: member.name || `멤버 ${idx + 1}`,
        gender: member.gender,
        saju: sajuInfo.saju,
        oheng: sajuInfo.oheng,
      };
    });

    // AI 분석 요청
    const prompt = buildTeamCompatibilityPrompt(memberSajuList, relationship);
    const response = await ai.models.generateContent({
      model: MODEL,
      contents: prompt,
      config: {
        systemInstruction: getSystemPrompt('date'),
        maxOutputTokens: 16384,
        temperature: 0.8,
      },
    });

    const result = { consultation: response.text };

    // 캐시 저장
    await pool.query(
      'INSERT INTO team_compatibility_cache (cache_key, result, year) VALUES ($1, $2, $3) ON CONFLICT (cache_key) DO NOTHING',
      [cacheKey, JSON.stringify(result), currentYear],
    );

    // 히스토리 저장
    await pool.query(
      `INSERT INTO team_compatibility_history (uid, cache_key, members, relationship, result)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.uid, cacheKey, JSON.stringify(members), relationship, JSON.stringify(result)],
    );

    res.json(result);
  } catch (err) {
    console.error('Team compatibility error:', err);
    res.status(500).json({ error: '팀 궁합 분석 중 오류가 발생했습니다.' });
  }
});

export default router;
