import ai from '../config/gemini.js';
import { SYSTEM_PROMPT, buildFortunePrompt, buildDailyPrompt, buildDiaryPrompt, buildCompatibilityPrompt } from '../prompts/system.js';
import { getSajuInfo, getTodayIljin } from './saju.js';

const MODEL = 'gemini-2.5-flash';

// ── 응답 캐시 ──────────────────────────────────────
const cache = new Map();

function getCached(key) {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function setCache(key, value, ttlMs) {
  cache.set(key, { value, expiresAt: Date.now() + ttlMs });
}

function msUntilMidnight() {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0);
  return midnight - now;
}

const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;

// ── Gemini 호출 ────────────────────────────────────
async function askGemini(userPrompt) {
  const response = await ai.models.generateContent({
    model: MODEL,
    contents: userPrompt,
    config: {
      systemInstruction: SYSTEM_PROMPT,
      maxOutputTokens: 8192,
      temperature: 0.8,
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

function parseFortuneResponse(text) {
  try {
    // Gemini가 ```json ... ``` 로 감쌀 수 있으므로 제거
    const cleaned = text.replace(/^```(?:json)?\s*\n?/m, '').replace(/\n?```\s*$/m, '').trim();
    const parsed = JSON.parse(cleaned);

    const interpretation = parsed.interpretation ?? '';
    const rawCats = parsed.categories ?? {};

    const categories = CATEGORY_META
      .filter(({ key }) => rawCats[key])
      .map(({ key, label, emoji }) => ({
        key,
        label,
        emoji,
        content: rawCats[key],
      }));

    return { interpretation, categories };
  } catch {
    // JSON 파싱 실패 시 fallback: 전체 텍스트를 interpretation으로
    return { interpretation: text, categories: [] };
  }
}

/**
 * 사주 해석 (캐시: 7일)
 */
export async function interpretFortune({ year, month, day, hour, minute, gender }) {
  const cacheKey = `fortune:${year}-${month}-${day}-${hour}-${minute}-${gender}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const prompt = buildFortunePrompt(sajuInfo, gender);
  const rawText = await askGemini(prompt);
  const { interpretation, categories } = parseFortuneResponse(rawText);

  const result = {
    saju: sajuInfo.saju,
    lunar: sajuInfo.lunar,
    oheng: {
      distribution: sajuInfo.oheng.distribution,
      dominant: sajuInfo.oheng.dominantInfo,
      weak: sajuInfo.oheng.weakInfo,
      summary: sajuInfo.oheng.summary,
    },
    interpretation,
    categories,
  };

  setCache(cacheKey, result, SEVEN_DAYS);
  return result;
}

/**
 * 오늘의 운세 (캐시: 자정까지)
 */
export async function getDailyFortune({ year, month, day, hour, minute, gender }) {
  const cacheKey = `daily:${year}-${month}-${day}-${hour}-${minute}-${gender}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const iljin = getTodayIljin();
  const prompt = buildDailyPrompt(sajuInfo, iljin, gender);
  const reading = await askGemini(prompt);

  const result = {
    date: iljin.date,
    iljin: iljin.dayPillar,
    reading,
  };

  setCache(cacheKey, result, msUntilMidnight());
  return result;
}

/**
 * 일기 상담 (캐시 없음 — 매번 다른 입력)
 */
export async function consultDiary({ year, month, day, hour, minute, gender, diaryText }) {
  const sajuInfo = getSajuInfo(year, month, day, hour, minute);
  const prompt = buildDiaryPrompt(sajuInfo, diaryText, gender);
  const consultation = await askGemini(prompt);

  return { consultation };
}

/**
 * 궁합 분석 (캐시: 7일)
 */
export async function getCompatibility({ my, partner, relationship }) {
  const cacheKey = `compat:${my.year}-${my.month}-${my.day}-${my.hour}-${my.minute}-${my.gender}`
    + `:${partner.year}-${partner.month}-${partner.day}-${partner.hour}-${partner.minute}-${partner.gender}`
    + `:${relationship}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const mySaju = getSajuInfo(my.year, my.month, my.day, my.hour, my.minute);
  const partnerSaju = getSajuInfo(partner.year, partner.month, partner.day, partner.hour, partner.minute);
  const prompt = buildCompatibilityPrompt(mySaju, partnerSaju, my.gender, partner.gender, relationship);
  const consultation = await askGemini(prompt);

  const result = { consultation };

  setCache(cacheKey, result, SEVEN_DAYS);
  return result;
}
