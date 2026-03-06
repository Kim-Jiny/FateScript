import ai from '../config/gemini.js';
import pool from '../config/db.js';
import { getSystemPrompt, buildFortunePrompt, buildDailyPrompt, buildCompatibilityPrompt, buildNameAnalysisPrompt, buildNameRecommendPrompt } from '../prompts/system.js';
import { getSajuInfo, getTodayIljin } from './saju.js';

const MODEL = 'gemini-2.5-flash';

// ── Gemini 호출 ────────────────────────────────────
async function askGemini(userPrompt, systemPrompt) {
  const response = await ai.models.generateContent({
    model: MODEL,
    contents: userPrompt,
    config: {
      systemInstruction: systemPrompt,
      maxOutputTokens: 8192,
      temperature: 0.8,
    },
  });
  return response.text;
}

async function askGeminiJson(userPrompt, systemPrompt) {
  const response = await ai.models.generateContent({
    model: MODEL,
    contents: userPrompt,
    config: {
      systemInstruction: systemPrompt,
      maxOutputTokens: 8192,
      temperature: 0.8,
      responseMimeType: 'application/json',
    },
  });
  return response.text;
}

// ── 카테고리 매핑 ──────────────────────────────────
const CATEGORY_META = [
  { key: 'love',          label: '연애운',        emoji: '💕' },
  { key: 'money',         label: '금전운',        emoji: '💰' },
  { key: 'career',        label: '직업과 적성',   emoji: '💼' },
  { key: 'health',        label: '건강운',        emoji: '🏥' },
  { key: 'relationships', label: '대인관계운',    emoji: '👥' },
  { key: 'yearFortune',   label: '올해의 운세',   emoji: '🌟' },
  { key: 'advice',        label: '운명선생의 한마디', emoji: '🍀' },
];

function extractJson(text) {
  // 1) ```json ... ``` 블록에서 추출
  const fenced = text.match(/```(?:json)?\s*\n?([\s\S]*?)\n?```/);
  if (fenced) {
    try { return JSON.parse(fenced[1].trim()); } catch {}
  }

  // 2) 첫 번째 { ... 마지막 } 추출
  const first = text.indexOf('{');
  const last = text.lastIndexOf('}');
  if (first !== -1 && last > first) {
    try { return JSON.parse(text.slice(first, last + 1)); } catch {}
  }

  // 3) 전체 시도
  try { return JSON.parse(text.trim()); } catch {}

  return null;
}

function parseFortuneResponse(text) {
  const parsed = extractJson(text);

  if (parsed && (parsed.manseryeok || parsed.interpretation)) {
    const rawCats = parsed.categories ?? {};

    const categories = CATEGORY_META
      .filter(({ key }) => rawCats[key])
      .map(({ key, label, emoji }) => ({
        key,
        label,
        emoji,
        content: rawCats[key],
      }));

    return {
      manseryeok: parsed.manseryeok ?? parsed.interpretation ?? '',
      yearFortune: parsed.yearFortune ?? '',
      interpretation: parsed.manseryeok ?? parsed.interpretation ?? '',
      categories,
    };
  }

  // JSON 파싱 실패 시 fallback: 전체 텍스트를 interpretation으로
  return { manseryeok: text, yearFortune: '', interpretation: text, categories: [] };
}

/**
 * 사주 해석 (DB 캐시: 같은 해 동안 유지)
 */
export async function interpretFortune({ year, month, day, hour, minute, gender }) {
  const currentYear = new Date().getFullYear();
  const cacheKey = `fortune:${year}-${month}-${day}-${hour}-${minute}-${gender}:${currentYear}`;

  // DB 캐시 조회
  const { rows } = await pool.query(
    'SELECT result FROM fortune_cache WHERE cache_key = $1',
    [cacheKey],
  );
  if (rows.length > 0) {
    console.log(`[cache hit] fortune ${cacheKey}`);
    return rows[0].result;
  }

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const prompt = buildFortunePrompt(sajuInfo, gender);
  const rawText = await askGemini(prompt, getSystemPrompt('year'));
  const { manseryeok, yearFortune, interpretation, categories } = parseFortuneResponse(rawText);

  const result = {
    saju: sajuInfo.saju,
    lunar: sajuInfo.lunar,
    oheng: {
      distribution: sajuInfo.oheng.distribution,
      dominant: sajuInfo.oheng.dominantInfo,
      weak: sajuInfo.oheng.weakInfo,
      summary: sajuInfo.oheng.summary,
    },
    manseryeok,
    yearFortune,
    interpretation,
    categories,
  };

  // DB 저장
  await pool.query(
    'INSERT INTO fortune_cache (cache_key, result, year) VALUES ($1, $2, $3) ON CONFLICT (cache_key) DO NOTHING',
    [cacheKey, JSON.stringify(result), currentYear],
  );
  console.log(`[cache set] fortune ${cacheKey}`);

  return result;
}

/**
 * 오늘의 운세 (DB 캐시: 같은 날 동안 유지)
 */
export async function getDailyFortune({ year, month, day, hour, minute, gender }) {
  const todayDate = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const cacheKey = `daily:${year}-${month}-${day}-${hour}-${minute}-${gender}:${todayDate}`;

  // DB 캐시 조회
  const { rows } = await pool.query(
    'SELECT result FROM daily_cache WHERE cache_key = $1',
    [cacheKey],
  );
  if (rows.length > 0) {
    console.log(`[cache hit] daily ${cacheKey}`);
    return rows[0].result;
  }

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const iljin = getTodayIljin();
  const prompt = buildDailyPrompt(sajuInfo, iljin, gender);
  const reading = await askGemini(prompt, getSystemPrompt('date'));

  const result = {
    date: iljin.date,
    iljin: iljin.dayPillar,
    reading,
  };

  // DB 저장
  await pool.query(
    'INSERT INTO daily_cache (cache_key, result, date) VALUES ($1, $2, $3) ON CONFLICT (cache_key) DO NOTHING',
    [cacheKey, JSON.stringify(result), todayDate],
  );
  console.log(`[cache set] daily ${cacheKey}`);

  return result;
}

/**
 * 성명학 이름 분석 (DB 캐시)
 */
export async function analyzeNameFortune({ year, month, day, hour, minute, gender, name }) {
  const cacheKey = `name-analysis:${name}:${year}-${month}-${day}-${hour}-${minute}-${gender}`;

  const { rows } = await pool.query(
    'SELECT result FROM name_analysis_cache WHERE cache_key = $1',
    [cacheKey],
  );
  if (rows.length > 0) {
    console.log(`[cache hit] name-analysis ${cacheKey}`);
    return rows[0].result;
  }

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const prompt = buildNameAnalysisPrompt(sajuInfo, name, gender);
  const rawText = await askGeminiJson(prompt, getSystemPrompt('year'));

  const result = extractJson(rawText) ?? JSON.parse(rawText);

  await pool.query(
    'INSERT INTO name_analysis_cache (cache_key, result) VALUES ($1, $2) ON CONFLICT (cache_key) DO NOTHING',
    [cacheKey, JSON.stringify(result)],
  );
  console.log(`[cache set] name-analysis ${cacheKey}`);

  return result;
}

/**
 * 성명학 이름 추천 (DB 캐시)
 */
export async function recommendNames({ year, month, day, hour, minute, gender, lastName }) {
  const cacheKey = `name-recommend:${lastName}:${year}-${month}-${day}-${hour}-${minute}-${gender}`;

  const { rows } = await pool.query(
    'SELECT result FROM name_analysis_cache WHERE cache_key = $1',
    [cacheKey],
  );
  if (rows.length > 0) {
    console.log(`[cache hit] name-recommend ${cacheKey}`);
    return rows[0].result;
  }

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const prompt = buildNameRecommendPrompt(sajuInfo, lastName, gender);
  const rawText = await askGeminiJson(prompt, getSystemPrompt('year'));

  const result = extractJson(rawText) ?? JSON.parse(rawText);

  await pool.query(
    'INSERT INTO name_analysis_cache (cache_key, result) VALUES ($1, $2) ON CONFLICT (cache_key) DO NOTHING',
    [cacheKey, JSON.stringify(result)],
  );
  console.log(`[cache set] name-recommend ${cacheKey}`);

  return result;
}

/**
 * 궁합 분석 (DB 캐시: 같은 해 동안 유지)
 */
export async function getCompatibility({ my, partner, relationship }) {
  const currentYear = new Date().getFullYear();
  const cacheKey = `compat:${my.year}-${my.month}-${my.day}-${my.hour}-${my.minute}-${my.gender}`
    + `:${partner.year}-${partner.month}-${partner.day}-${partner.hour}-${partner.minute}-${partner.gender}`
    + `:${relationship}:${currentYear}`;

  // DB 캐시 조회
  const { rows } = await pool.query(
    'SELECT result FROM compatibility_cache WHERE cache_key = $1',
    [cacheKey],
  );
  if (rows.length > 0) {
    console.log(`[cache hit] compatibility ${cacheKey}`);
    return rows[0].result;
  }

  const mySaju = getSajuInfo(my.year, my.month, my.day, my.hour, my.minute);
  const partnerSaju = getSajuInfo(partner.year, partner.month, partner.day, partner.hour, partner.minute);
  const prompt = buildCompatibilityPrompt(mySaju, partnerSaju, my.gender, partner.gender, relationship);
  const consultation = await askGemini(prompt, getSystemPrompt('date'));

  const result = { consultation };

  // DB 저장
  await pool.query(
    'INSERT INTO compatibility_cache (cache_key, result, year) VALUES ($1, $2, $3) ON CONFLICT (cache_key) DO NOTHING',
    [cacheKey, JSON.stringify(result), currentYear],
  );
  console.log(`[cache set] compatibility ${cacheKey}`);

  return result;
}

// ── 궁합 히스토리 ────────────────────────────────────

/**
 * 궁합 히스토리 저장
 */
export async function saveCompatibilityHistory({
  uid, myBirthDate, myBirthTime, myGender,
  partnerBirthDate, partnerBirthTime, partnerGender,
  relationship, result,
}) {
  const currentYear = new Date().getFullYear();
  const cacheKey = `compat:${myBirthDate}-${myBirthTime}-${myGender}`
    + `:${partnerBirthDate}-${partnerBirthTime}-${partnerGender}`
    + `:${relationship}:${currentYear}`;

  // 같은 캐시키의 히스토리가 이미 있으면 저장하지 않음
  const { rows } = await pool.query(
    'SELECT id FROM compatibility_history WHERE uid = $1 AND cache_key = $2',
    [uid, cacheKey],
  );
  if (rows.length > 0) return;

  await pool.query(
    `INSERT INTO compatibility_history
      (uid, cache_key, my_birth_date, my_birth_time, my_gender,
       partner_birth_date, partner_birth_time, partner_gender,
       relationship, result)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
    [uid, cacheKey, myBirthDate, myBirthTime ?? 'unknown', myGender,
     partnerBirthDate, partnerBirthTime ?? 'unknown', partnerGender,
     relationship, JSON.stringify(result)],
  );
}

/**
 * 궁합 히스토리 조회
 */
export async function getCompatibilityHistory(uid) {
  const { rows } = await pool.query(
    `SELECT id, my_birth_date, my_birth_time, my_gender,
            partner_birth_date, partner_birth_time, partner_gender,
            relationship, result, created_at
     FROM compatibility_history
     WHERE uid = $1
     ORDER BY created_at DESC`,
    [uid],
  );
  return rows.map((r) => ({
    id: r.id,
    myBirthDate: r.my_birth_date,
    myBirthTime: r.my_birth_time,
    myGender: r.my_gender,
    partnerBirthDate: r.partner_birth_date,
    partnerBirthTime: r.partner_birth_time,
    partnerGender: r.partner_gender,
    relationship: r.relationship,
    result: r.result,
    createdAt: r.created_at,
  }));
}

/**
 * 궁합 히스토리 삭제
 */
export async function deleteCompatibilityHistory(uid, id) {
  await pool.query(
    'DELETE FROM compatibility_history WHERE uid = $1 AND id = $2',
    [uid, id],
  );
}
