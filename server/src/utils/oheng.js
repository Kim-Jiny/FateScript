import { getPillarByHangul } from '@fullstackfamily/manseryeok';

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
