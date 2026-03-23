import { getPillarByHangul, getGapja } from '@fullstackfamily/manseryeok';

const OHENG_NAMES = { 목: 'wood', 화: 'fire', 토: 'earth', 금: 'metal', 수: 'water' };
const OHENG_EMOJI = { 목: '🌳', 화: '🔥', 토: '⛰️', 금: '⚙️', 수: '💧' };
const OHENG_COLORS = { 목: '청(靑)', 화: '적(赤)', 토: '황(黃)', 금: '백(白)', 수: '흑(黑)' };

/**
 * 사주 4주에서 8개 오행을 추출하고 분포를 계산한다.
 * @param {{ yearPillar: string, monthPillar: string, dayPillar: string, hourPillar: string|null }} saju
 * @returns {{ elements: Array, distribution: Record<string,number>, dominant: string, weak: string, summary: string }}
 */
export function analyzeOheng(saju) {
  const pillars = [saju.yearPillar, saju.monthPillar, saju.dayPillar];
  if (saju.hourPillar) pillars.push(saju.hourPillar);

  const elements = [];
  for (const pillarName of pillars) {
    const pillar = getPillarByHangul(pillarName);
    if (!pillar) continue;
    elements.push({
      position: pillarName,
      stem: { char: pillar.tiangan.hangul, element: pillar.tiangan.element },
      branch: { char: pillar.dizhi.hangul, element: pillar.dizhi.element },
    });
  }

  const distribution = { 목: 0, 화: 0, 토: 0, 금: 0, 수: 0 };
  for (const el of elements) {
    distribution[el.stem.element]++;
    distribution[el.branch.element]++;
  }

  const sorted = Object.entries(distribution).sort((a, b) => b[1] - a[1]);
  const dominant = sorted[0][0];
  const weak = sorted[sorted.length - 1][0];

  const total = Object.values(distribution).reduce((s, v) => s + v, 0);
  const summaryParts = sorted.map(
    ([k, v]) => `${k}(${OHENG_NAMES[k]}) ${v}개 ${Math.round((v / total) * 100)}%`
  );

  return {
    elements,
    distribution,
    dominant,
    weak,
    dominantInfo: { name: dominant, english: OHENG_NAMES[dominant], emoji: OHENG_EMOJI[dominant], color: OHENG_COLORS[dominant] },
    weakInfo: { name: weak, english: OHENG_NAMES[weak], emoji: OHENG_EMOJI[weak], color: OHENG_COLORS[weak] },
    summary: summaryParts.join(', '),
  };
}

/**
 * getGapja() 결과(년/월/일 기둥)에서 오행 분석
 * @param {object} gapja - getGapja() 반환값
 * @returns {{ distribution, dominant, weak, dominantInfo, weakInfo, summary }}
 */
export function analyzeOhengFromGapja(gapja) {
  const pillars = [gapja.yearPillar, gapja.monthPillar, gapja.dayPillar];

  const elements = [];
  for (const pillarName of pillars) {
    const pillar = getPillarByHangul(pillarName);
    if (!pillar) continue;
    elements.push({
      position: pillarName,
      stem: { char: pillar.tiangan.hangul, element: pillar.tiangan.element },
      branch: { char: pillar.dizhi.hangul, element: pillar.dizhi.element },
    });
  }

  const distribution = { 목: 0, 화: 0, 토: 0, 금: 0, 수: 0 };
  for (const el of elements) {
    distribution[el.stem.element]++;
    distribution[el.branch.element]++;
  }

  const sorted = Object.entries(distribution).sort((a, b) => b[1] - a[1]);
  const dominant = sorted[0][0];
  const weak = sorted[sorted.length - 1][0];

  const total = Object.values(distribution).reduce((s, v) => s + v, 0);
  const summaryParts = sorted.map(
    ([k, v]) => `${k}(${OHENG_NAMES[k]}) ${v}개 ${Math.round((v / total) * 100)}%`
  );

  return {
    elements,
    distribution,
    dominant,
    weak,
    dominantInfo: { name: dominant, english: OHENG_NAMES[dominant], emoji: OHENG_EMOJI[dominant], color: OHENG_COLORS[dominant] },
    weakInfo: { name: weak, english: OHENG_NAMES[weak], emoji: OHENG_EMOJI[weak], color: OHENG_COLORS[weak] },
    summary: summaryParts.join(', '),
  };
}

/**
 * 두 오행 분포 간의 상생/상극 점수 계산 (0-100)
 * 상생 사이클: 목→화→토→금→수→목
 * @param {Record<string,number>} userDist - 사용자 오행 분포
 * @param {Record<string,number>} monthDist - 해당 기간 오행 분포
 * @returns {number} 0-100 점수
 */
export function calculateMonthScore(userDist, monthDist) {
  const order = ['목', '화', '토', '금', '수'];

  // 상생 쌍 (생하는 → 생받는)
  const sangsaeng = [['목','화'], ['화','토'], ['토','금'], ['금','수'], ['수','목']];
  // 상극 쌍 (극하는 → 극받는)
  const sanggeuk = [['목','토'], ['토','수'], ['수','화'], ['화','금'], ['금','목']];

  let score = 50; // 기본 점수

  const userTotal = Object.values(userDist).reduce((s, v) => s + v, 0) || 1;
  const monthTotal = Object.values(monthDist).reduce((s, v) => s + v, 0) || 1;

  // 상생 보너스: 해당 월의 강한 오행이 사용자의 약한 오행을 상생하면 가산
  for (const [giver, receiver] of sangsaeng) {
    const giverRatio = (monthDist[giver] || 0) / monthTotal;
    const receiverNeed = 1 - (userDist[receiver] || 0) / userTotal;
    score += Math.round(giverRatio * receiverNeed * 30);
  }

  // 상극 감점: 해당 월의 강한 오행이 사용자의 강한 오행을 상극하면 감점
  for (const [attacker, target] of sanggeuk) {
    const attackRatio = (monthDist[attacker] || 0) / monthTotal;
    const targetRatio = (userDist[target] || 0) / userTotal;
    score -= Math.round(attackRatio * targetRatio * 20);
  }

  // 오행 보완 보너스: 사용자에게 부족한 오행이 해당 월에 강하면 가산
  for (const el of order) {
    const userRatio = (userDist[el] || 0) / userTotal;
    const monthRatio = (monthDist[el] || 0) / monthTotal;
    if (userRatio < 0.15 && monthRatio > 0.3) {
      score += 10;
    }
  }

  return Math.max(0, Math.min(100, score));
}

/**
 * 일주(dayPillar) 중심의 택일 점수 계산 (0-100)
 * 같은 월 내에서는 년주·월주가 동일하므로, 일주의 천간·지지를 세밀하게 분석한다.
 * @param {Record<string,number>} userDist - 사용자 사주 오행 분포
 * @param {string} userDayElement - 사용자 일간 오행 (일주 천간의 오행)
 * @param {object} gapja - getGapja() 반환값
 * @returns {number} 0-100 점수
 */
export function calculateDayScore(userDist, userDayElement, gapja) {
  const dayPillar = getPillarByHangul(gapja.dayPillar);
  if (!dayPillar) return 50;

  const dayStem = dayPillar.tiangan.element;   // 해당 날 일간 오행
  const dayBranch = dayPillar.dizhi.element;   // 해당 날 일지 오행

  const sangsaeng = { 목: '화', 화: '토', 토: '금', 금: '수', 수: '목' };
  const sanggeuk = { 목: '토', 토: '수', 수: '화', 화: '금', 금: '목' };
  // 역극: 누가 X를 극하는가
  const attackedBy = { 목: '금', 화: '수', 토: '목', 금: '화', 수: '토' };

  const userTotal = Object.values(userDist).reduce((s, v) => s + v, 0) || 1;

  let score = 50;

  // ── 1. 일간(dayStem)과 사용자 사주의 관계 (가중치 높음) ──

  // 일간이 생하는 오행이 사용자에게 부족하면 크게 가산
  const stemGenerates = sangsaeng[dayStem];
  const stemGenNeed = 1 - (userDist[stemGenerates] || 0) / userTotal;
  score += Math.round(stemGenNeed * 18);

  // 사용자의 약한 오행을 일간이 직접 보완하면 가산
  const stemUserRatio = (userDist[dayStem] || 0) / userTotal;
  if (stemUserRatio < 0.15) score += 12;
  else if (stemUserRatio < 0.25) score += 5;

  // 일간이 사용자의 강한 오행을 극하면 감점
  const stemAttacks = sanggeuk[dayStem];
  const attackedRatio = (userDist[stemAttacks] || 0) / userTotal;
  score -= Math.round(attackedRatio * 14);

  // 사용자의 강한 오행이 일간을 극하면 감점 (역극)
  const stemAttacker = attackedBy[dayStem];
  const attackerRatio = (userDist[stemAttacker] || 0) / userTotal;
  score -= Math.round(attackerRatio * 10);

  // ── 2. 일지(dayBranch)와 사용자 사주의 관계 ──

  const branchGenerates = sangsaeng[dayBranch];
  const branchGenNeed = 1 - (userDist[branchGenerates] || 0) / userTotal;
  score += Math.round(branchGenNeed * 12);

  const branchUserRatio = (userDist[dayBranch] || 0) / userTotal;
  if (branchUserRatio < 0.15) score += 8;

  const branchAttacks = sanggeuk[dayBranch];
  const branchAttackedRatio = (userDist[branchAttacks] || 0) / userTotal;
  score -= Math.round(branchAttackedRatio * 8);

  // ── 3. 일간과 사용자 일간의 직접 관계 ──

  if (dayStem === userDayElement) {
    // 비겁(같은 오행) — 힘을 더해줌, 약간 가산
    score += 5;
  } else if (sangsaeng[userDayElement] === dayStem) {
    // 사용자가 생하는 오행 → 식상(설기) — 약간 감점
    score -= 3;
  } else if (sangsaeng[dayStem] === userDayElement) {
    // 일간이 사용자를 생함 → 인성 — 가산
    score += 8;
  } else if (sanggeuk[dayStem] === userDayElement) {
    // 일간이 사용자를 극함 → 관성 — 감점
    score -= 6;
  } else if (sanggeuk[userDayElement] === dayStem) {
    // 사용자가 일간을 극함 → 재성 — 약간 가산
    score += 3;
  }

  // ── 4. 일간·일지 조합 보너스/패널티 ──

  // 천간·지지가 같은 오행이면 그 날의 기운이 매우 강함
  if (dayStem === dayBranch) {
    // 사용자에게 부족한 오행이면 큰 보너스, 과잉이면 감점
    if (stemUserRatio < 0.15) score += 8;
    else if (stemUserRatio > 0.4) score -= 5;
  }

  return Math.max(0, Math.min(100, score));
}
