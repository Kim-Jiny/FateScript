import { calculateSaju, solarToLunar, getGapja } from '@fullstackfamily/manseryeok';
import { analyzeOheng } from '../utils/oheng.js';

/**
 * 생년월일시로 사주 정보를 계산한다.
 * @param {number} year
 * @param {number} month
 * @param {number} day
 * @param {number|null} hour
 * @param {number|null} minute
 * @returns {object}
 */
export function getSajuInfo(year, month, day, hour = null, minute = null) {
  const hasTime = hour !== null && hour !== undefined;
  const saju = hasTime
    ? calculateSaju(year, month, day, hour, minute ?? 0)
    : calculateSaju(year, month, day);

  const lunar = solarToLunar(year, month, day);
  const oheng = analyzeOheng(saju);

  return {
    saju: {
      yearPillar: { hangul: saju.yearPillar, hanja: saju.yearPillarHanja },
      monthPillar: { hangul: saju.monthPillar, hanja: saju.monthPillarHanja },
      dayPillar: { hangul: saju.dayPillar, hanja: saju.dayPillarHanja },
      hourPillar: saju.hourPillar
        ? { hangul: saju.hourPillar, hanja: saju.hourPillarHanja }
        : null,
    },
    lunar: {
      year: lunar.lunar.year,
      month: lunar.lunar.month,
      day: lunar.lunar.day,
      isLeapMonth: lunar.lunar.isLeapMonth,
    },
    oheng,
    isTimeCorrected: saju.isTimeCorrected ?? false,
  };
}

/**
 * 오늘 날짜의 일진(日辰)을 가져온다.
 */
export function getTodayIljin() {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  const day = now.getDate();

  const gapja = getGapja(year, month, day);
  return {
    date: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
    dayPillar: {
      hangul: gapja.dayPillar,
      hanja: gapja.dayPillarHanja,
    },
    monthPillar: {
      hangul: gapja.monthPillar,
      hanja: gapja.monthPillarHanja,
    },
    yearPillar: {
      hangul: gapja.yearPillar,
      hanja: gapja.yearPillarHanja,
    },
  };
}
