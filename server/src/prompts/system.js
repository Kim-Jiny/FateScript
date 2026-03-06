const today = new Date();
const currentDateStr = `${today.getFullYear()}년 ${today.getMonth() + 1}월 ${today.getDate()}일`;

export const SYSTEM_PROMPT = `당신은 '운명선생'입니다. 30년 경력의 사주명리학 전문가이자 따뜻한 인생 상담사입니다.

## 현재 날짜
오늘은 ${currentDateStr}입니다. 올해는 ${today.getFullYear()}년입니다. 운세 분석 시 반드시 이 날짜를 기준으로 하세요.

## 성격과 말투
- 따뜻하고 격려하는 존댓말을 사용합니다
- "~하시겠네요", "~이시군요" 같은 존칭을 씁니다
- 사주 용어를 쓸 때는 반드시 쉬운 설명을 함께 덧붙입니다
- 부정적인 내용도 희망적인 조언과 함께 전달합니다
- 마크다운 형식으로 보기 좋게 정리합니다

## 규칙
- 사주 해석은 전통 명리학에 기반하되, 현대적 맥락으로 풀어냅니다
- 건강, 투자 등 민감한 주제는 단정짓지 않고 참고용임을 밝힙니다
- 응답은 한국어로만 합니다`;

/**
 * 사주 해석 프롬프트
 */
export function buildFortunePrompt(sajuInfo, gender) {
  const { saju, lunar, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성(건명)' : '여성(곤명)';

  return `## 사주 분석 요청

**성별**: ${genderText}
**음력 생일**: ${lunar.year}년 ${lunar.month}월 ${lunar.day}일${lunar.isLeapMonth ? ' (윤달)' : ''}

### 사주팔자 (四柱八字)
| 구분 | 년주(年柱) | 월주(月柱) | 일주(日柱) | 시주(時柱) |
|------|-----------|-----------|-----------|-----------|
| 한글 | ${saju.yearPillar.hangul} | ${saju.monthPillar.hangul} | ${saju.dayPillar.hangul} | ${saju.hourPillar?.hangul ?? '미상'} |
| 한자 | ${saju.yearPillar.hanja} | ${saju.monthPillar.hanja} | ${saju.dayPillar.hanja} | ${saju.hourPillar?.hanja ?? '미상'} |

### 오행 분포
${oheng.summary}
- 가장 강한 오행: ${oheng.dominant} (${oheng.dominantInfo.emoji})
- 가장 약한 오행: ${oheng.weak} (${oheng.weakInfo.emoji})

다음 JSON 형식으로 분석 결과를 응답해 주세요. 반드시 JSON만 출력하고 다른 텍스트는 포함하지 마세요.
각 필드의 값은 마크다운 형식의 문자열입니다.

\`\`\`json
{
  "interpretation": "전체 사주 개요 (일간의 성격/기질 + 오행 균형 요약을 포함한 종합 분석)",
  "categories": {
    "love": "연애운 - 사주로 본 연애 성향, 이상적인 파트너, 연애 시 주의점 등",
    "money": "금전운 - 재물운, 투자 성향, 재정 관리 조언 등",
    "career": "직업과 적성 - 어울리는 분야, 재능, 진로 조언 등",
    "health": "건강운 - 오행 기반 건강 취약점, 건강 관리 조언 등",
    "relationships": "대인관계운 - 사주로 본 대인관계 특성, 소통 스타일 등",
    "yearFortune": "올해의 운세 - ${today.getFullYear()}년 대운/세운 흐름, 올해 주의점과 기회",
    "advice": "운명선생의 한마디 - 따뜻한 격려와 인생 조언"
  }
}
\`\`\``;
}

/**
 * 오늘의 운세 프롬프트
 */
export function buildDailyPrompt(sajuInfo, iljin, gender) {
  const { saju, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성' : '여성';

  return `## 오늘의 운세 요청

**성별**: ${genderText}
**오늘 날짜**: ${iljin.date}
**오늘의 일진**: ${iljin.dayPillar.hangul} (${iljin.dayPillar.hanja})

### 내 사주
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${saju.yearPillar.hangul} | ${saju.monthPillar.hangul} | ${saju.dayPillar.hangul} | ${saju.hourPillar?.hangul ?? '미상'} |

### 내 오행 분포
${oheng.summary}

오늘의 일진과 내 사주의 관계를 분석하여 다음을 마크다운으로 알려주세요:
1. **오늘의 총운** (⭐ 5점 만점으로 표시)
2. **오늘의 키워드** (3개)
3. **금전운** 💰
4. **대인관계운** 👥
5. **건강 주의사항** 🏥
6. **행운의 요소** (색상, 방향, 숫자)
7. **운명선생의 오늘 한마디** 🍀`;
}

/**
 * 일기 상담 프롬프트
 */
export function buildDiaryPrompt(sajuInfo, diaryText, gender) {
  const { saju, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성' : '여성';

  return `## 일기 상담 요청

**성별**: ${genderText}

### 내 사주 요약
일주: ${saju.dayPillar.hangul} (${saju.dayPillar.hanja})
주된 오행: ${oheng.dominant} (${oheng.dominantInfo.emoji})

### 오늘의 일기
${diaryText}

위 일기 내용을 사주명리학 관점에서 상담해 주세요:
1. **일기 속 감정 읽기** - 글에서 느껴지는 감정을 공감하며 읽어주세요
2. **사주 관점의 해석** - 이 분의 사주 특성과 오늘 겪은 일의 연결고리
3. **오행 에너지 조언** - 현재 필요한 오행 에너지와 보충 방법
4. **운명선생의 따뜻한 한마디** - 격려와 응원의 메시지

공감과 위로를 우선으로 하되, 사주 전문가로서의 통찰도 함께 전해주세요.
답변은 대화하듯 따뜻하게 해주세요.`;
}

/**
 * 궁합 분석 프롬프트
 */
export function buildCompatibilityPrompt(mySaju, partnerSaju, myGender, partnerGender, relationship) {
  const myGenderText = myGender === 'male' ? '남성' : '여성';
  const partnerGenderText = partnerGender === 'male' ? '남성' : '여성';

  const relationshipLabels = {
    lover: '연인',
    spouse: '배우자',
    friend: '친구',
    colleague: '동료',
    family: '가족',
  };
  const relationshipText = relationshipLabels[relationship] ?? relationship;

  return `## 궁합 분석 요청

**관계**: ${relationshipText}

### 나의 사주
**성별**: ${myGenderText}
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${mySaju.saju.yearPillar.hangul} | ${mySaju.saju.monthPillar.hangul} | ${mySaju.saju.dayPillar.hangul} | ${mySaju.saju.hourPillar?.hangul ?? '미상'} |

**오행 분포**: ${mySaju.oheng.summary}
- 강한 오행: ${mySaju.oheng.dominant} (${mySaju.oheng.dominantInfo.emoji})
- 약한 오행: ${mySaju.oheng.weak} (${mySaju.oheng.weakInfo.emoji})

### 상대방의 사주
**성별**: ${partnerGenderText}
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${partnerSaju.saju.yearPillar.hangul} | ${partnerSaju.saju.monthPillar.hangul} | ${partnerSaju.saju.dayPillar.hangul} | ${partnerSaju.saju.hourPillar?.hangul ?? '미상'} |

**오행 분포**: ${partnerSaju.oheng.summary}
- 강한 오행: ${partnerSaju.oheng.dominant} (${partnerSaju.oheng.dominantInfo.emoji})
- 약한 오행: ${partnerSaju.oheng.weak} (${partnerSaju.oheng.weakInfo.emoji})

두 사람의 사주를 비교하여 다음을 마크다운 형식으로 분석해 주세요:
1. **궁합 총점** (⭐ 100점 만점으로 표시)
2. **일간(日干) 관계** - 두 사람 일간의 합(合)·충(沖) 관계 분석
3. **오행 보완 분석** - 서로의 오행이 어떻게 보완되는지
4. **성격 궁합** - 사주로 본 두 사람의 성격 조화
5. **${relationshipText} 관계에서의 조언** - 이 관계 유형에 맞는 구체적 조언
6. **주의할 점** - 갈등이 생길 수 있는 부분과 해결 방법
7. **운명선생의 궁합 한마디** - 따뜻한 격려와 응원`;
}
