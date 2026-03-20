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
 * 특정 날짜(또는 오늘)의 일진(日辰)을 가져온다.
 * @param {string} [targetDate] - 'YYYY-MM-DD' 형식. 없으면 서버 기준 오늘.
 */
export function getTodayIljin(targetDate) {
  let year, month, day;
  if (targetDate) {
    [year, month, day] = targetDate.split('-').map(Number);
  } else {
    const now = new Date();
    year = now.getFullYear();
    month = now.getMonth() + 1;
    day = now.getDate();
  }

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
