/**
 * System prompt 생성
 * @param {'year'|'date'} mode - 'year': 연도만 포함 (fortune/name-analysis), 'date': 오늘 날짜 포함 (daily/compatibility)
 */
export function getSystemPrompt(mode = 'date') {
  const today = new Date();
  const year = today.getFullYear();

  const dateSection = mode === 'year'
    ? `올해는 ${year}년입니다. 운세 분석 시 반드시 이 연도를 기준으로 하세요.`
    : `오늘은 ${year}년 ${today.getMonth() + 1}월 ${today.getDate()}일입니다. 올해는 ${year}년입니다. 운세 분석 시 반드시 이 날짜를 기준으로 하세요.`;

  return `당신은 '운명선생'입니다. 30년 경력의 사주명리학 전문가이자 따뜻한 인생 상담사입니다.

## 현재 날짜
${dateSection}

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
}

/**
 * 사주 해석 프롬프트
 */
export function buildFortunePrompt(sajuInfo, gender) {
  const { saju, lunar, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성(건명)' : '여성(곤명)';
  const currentYear = new Date().getFullYear();

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
각 필드의 값은 마크다운 형식의 문자열입니다. 각 섹션은 충분히 상세하게 작성해 주세요.

\`\`\`json
{
  "manseryeok": "만세력 기반 사주팔자 상세 풀이. 다음을 모두 포함: 1) 일간(日干) 분석 - 일간의 성격, 기질, 성향 2) 사주 각 기둥별 천간·지지 해석 3) 천간·지지 간 합(合)·충(沖)·형(刑)·파(破)·해(害) 관계 분석 4) 십성(十星) 분석 - 식신, 상관, 정재, 편재, 정관, 편관, 정인, 편인, 비견, 겁재 5) 용신(用神)과 기신(忌神) 분석 6) 오행 균형 종합 평가",
  "yearFortune": "${currentYear}년 올해의 운세. 다음을 모두 포함: 1) 올해 세운(歲運) 천간·지지와 사주의 관계 2) 대운(大運) 흐름 3) 올해 특히 좋은 시기와 조심해야 할 시기 4) 올해의 핵심 키워드와 조언",
  "categories": {
    "love": "연애운 - 사주로 본 연애 성향, 이상적인 파트너, 연애 시 주의점 등",
    "money": "금전운 - 재물운, 투자 성향, 재정 관리 조언 등",
    "career": "직업과 적성 - 어울리는 분야, 재능, 진로 조언 등",
    "health": "건강운 - 오행 기반 건강 취약점, 건강 관리 조언 등",
    "relationships": "대인관계운 - 사주로 본 대인관계 특성, 소통 스타일 등",
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
 * 성명학 이름 분석 프롬프트
 */
export function buildNameAnalysisPrompt(sajuInfo, name, gender) {
  const { saju, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성' : '여성';

  return `## 성명학 이름 분석 요청

**이름**: ${name}
**성별**: ${genderText}

### 사주 정보
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${saju.yearPillar.hangul} | ${saju.monthPillar.hangul} | ${saju.dayPillar.hangul} | ${saju.hourPillar?.hangul ?? '미상'} |

### 오행 분포
${oheng.summary}
- 강한 오행: ${oheng.dominant} (${oheng.dominantInfo.emoji})
- 약한 오행: ${oheng.weak} (${oheng.weakInfo.emoji})

이름의 한자 획수, 오행, 음양을 분석하고 사주와의 궁합을 평가해 주세요.
반드시 아래 JSON 형식으로만 응답하고 다른 텍스트는 포함하지 마세요.

\`\`\`json
{
  "characters": [
    {
      "char": "글자",
      "hanja": "한자 (대표적 한자, 없으면 null)",
      "strokes": 획수,
      "oheng": "오행",
      "yinYang": "음/양"
    }
  ],
  "ohengBalance": "이름의 오행 균형 분석 (마크다운)",
  "yinYangBalance": "이름의 음양 균형 분석 (마크다운)",
  "sajuCompatibility": "사주와 이름의 궁합 분석 (마크다운)",
  "strengths": ["강점1", "강점2", "강점3"],
  "cautions": ["주의점1", "주의점2"],
  "overallScore": 85,
  "advice": "운명선생의 종합 조언 (마크다운)"
}
\`\`\``;
}

/**
 * 성명학 이름 추천 프롬프트
 */
export function buildNameRecommendPrompt(sajuInfo, lastName, gender) {
  const { saju, oheng } = sajuInfo;
  const genderText = gender === 'male' ? '남성' : '여성';

  return `## 성명학 이름 추천 요청

**성(姓)**: ${lastName}
**성별**: ${genderText}

### 사주 정보
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${saju.yearPillar.hangul} | ${saju.monthPillar.hangul} | ${saju.dayPillar.hangul} | ${saju.hourPillar?.hangul ?? '미상'} |

### 오행 분포
${oheng.summary}
- 강한 오행: ${oheng.dominant} (${oheng.dominantInfo.emoji})
- 약한 오행: ${oheng.weak} (${oheng.weakInfo.emoji})

이 사주에 맞는 이름 5개를 추천해 주세요.
반드시 아래 JSON 형식으로만 응답하고 다른 텍스트는 포함하지 마세요.

\`\`\`json
{
  "recommendations": [
    {
      "name": "추천이름 (한글)",
      "hanja": "추천이름 (한자)",
      "meaning": "이름의 뜻",
      "strokes": [획수1, 획수2],
      "ohengAnalysis": "이름의 오행 분석",
      "sajuFit": "사주와의 적합성 설명",
      "score": 92
    }
  ],
  "selectionCriteria": "이름 선정 기준 설명 (마크다운)",
  "advice": "운명선생의 종합 조언 (마크다운)"
}
\`\`\``;
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

/**
 * 택일/길일추천 프롬프트
 */
export function buildAuspiciousDatePrompt(sajuInfo, top5Dates, eventType) {
  const { saju, oheng } = sajuInfo;

  const eventLabels = {
    move: '이사',
    wedding: '결혼',
    business: '개업',
    travel: '여행',
    interview: '면접',
  };
  const eventText = eventLabels[eventType] ?? eventType;

  const datesInfo = top5Dates.map((d, i) =>
    `${i + 1}위: ${d.date} — 일진: ${d.pillar}(${d.pillarHanja}), 상생점수: ${d.score}점`
  ).join('\n');

  return `## 택일/길일추천 요청

**행사 유형**: ${eventText}

### 내 사주
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${saju.yearPillar.hangul} | ${saju.monthPillar.hangul} | ${saju.dayPillar.hangul} | ${saju.hourPillar?.hangul ?? '미상'} |

### 내 오행 분포
${oheng.summary}
- 강한 오행: ${oheng.dominant} (${oheng.dominantInfo.emoji})
- 약한 오행: ${oheng.weak} (${oheng.weakInfo.emoji})

### 추천 후보 날짜 (오행 상생 점수 기준 상위 5일)
${datesInfo}

위 5개 날짜에 대해 다음을 마크다운으로 분석해 주세요:
1. **각 날짜가 왜 좋은지** - 일진과 사주의 관계, 오행 상생 분석
2. **주의할 점** - 각 날짜의 잠재적 주의사항
3. **최종 추천** - 가장 추천하는 날짜와 그 이유
4. **${eventText} 관련 종합 조언** - 사주로 본 ${eventText}에 대한 구체적 조언`;
}

/**
 * 팀 궁합 분석 프롬프트
 */
export function buildTeamCompatibilityPrompt(memberSajuList, relationship) {
  const relationshipLabels = {
    team: '팀/프로젝트',
    friends: '친구 모임',
    family: '가족',
    business: '비즈니스 파트너',
  };
  const relText = relationshipLabels[relationship] ?? relationship;

  let membersSection = '';
  for (const member of memberSajuList) {
    const genderText = member.gender === 'male' ? '남성' : '여성';
    membersSection += `
### ${member.name} (${genderText})
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| ${member.saju.yearPillar.hangul} | ${member.saju.monthPillar.hangul} | ${member.saju.dayPillar.hangul} | ${member.saju.hourPillar?.hangul ?? '미상'} |

**오행**: ${member.oheng.summary}
- 강한 오행: ${member.oheng.dominant} (${member.oheng.dominantInfo.emoji})
- 약한 오행: ${member.oheng.weak} (${member.oheng.weakInfo.emoji})
`;
  }

  return `## 팀 궁합 분석 요청

**관계 유형**: ${relText}
**인원**: ${memberSajuList.length}명

${membersSection}

위 ${memberSajuList.length}명의 사주를 종합 분석하여 다음을 마크다운으로 알려주세요:
1. **팀 궁합 총점** (⭐ 100점 만점)
2. **팀 오행 분포 분석** - 전체 팀의 오행 균형, 부족한/과잉한 오행
3. **주요 페어별 궁합** - 특히 잘 맞는 조합과 주의가 필요한 조합
4. **팀 역학과 역할 분석** - 각 멤버가 팀에서 맡으면 좋을 역할
5. **갈등 요소와 해결 방안** - 잠재적 갈등 지점과 극복법
6. **팀 시너지 포인트** - 이 팀의 강점과 잘할 수 있는 분야
7. **운명선생의 팀 궁합 한마디** - 따뜻한 격려와 팀 조언`;
}
