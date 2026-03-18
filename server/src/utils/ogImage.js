import sharp from 'sharp';

const TYPE_CONFIG = {
  fortune:        { icon: '卦', title: '사주팔자',   desc: 'AI가 분석한 사주팔자 결과입니다' },
  daily:          { icon: '日', title: '오늘의 운세', desc: '오늘 하루의 운세를 확인하세요' },
  compatibility:  { icon: '合', title: '궁합 분석',   desc: 'AI가 분석한 궁합 결과입니다' },
  name_analysis:  { icon: '名', title: '이름 분석',   desc: 'AI 성명학 이름 분석 결과입니다' },
  name_recommend: { icon: '字', title: '이름 추천',   desc: 'AI 성명학 이름 추천 결과입니다' },
};

function esc(str) {
  return (str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

/**
 * 공유 결과의 OG 이미지 생성 (1200x630 PNG)
 */
export async function generateOgImage(type, data) {
  const config = TYPE_CONFIG[type] || TYPE_CONFIG.fortune;

  let subText = '';
  if (type === 'daily' && data?.date) {
    subText = data.date;
  } else if (type === 'name_analysis' && data?.overallScore) {
    subText = `총점 ${data.overallScore}점`;
  }

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1a1145"/>
      <stop offset="50%" stop-color="#2d1b69"/>
      <stop offset="100%" stop-color="#4a2c8a"/>
    </linearGradient>
    <linearGradient id="acc" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#a78bfa"/>
      <stop offset="100%" stop-color="#c084fc"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>

  <!-- 장식 -->
  <circle cx="1050" cy="100" r="200" fill="#8A4FFF" opacity="0.08"/>
  <circle cx="150" cy="530" r="150" fill="#8A4FFF" opacity="0.06"/>

  <!-- 한자 아이콘 -->
  <circle cx="160" cy="260" r="60" fill="#8A4FFF" opacity="0.2"/>
  <text x="160" y="280" fill="#e9d5ff" font-family="serif" font-size="56" font-weight="700" text-anchor="middle">${config.icon}</text>

  <!-- 앱 이름 -->
  <text x="100" y="100" fill="#a78bfa" font-family="sans-serif" font-size="28" font-weight="600" opacity="0.9">운명일기</text>
  <rect x="100" y="118" width="60" height="3" rx="2" fill="url(#acc)" opacity="0.6"/>

  <!-- 타입 제목 -->
  <text x="250" y="250" fill="#ffffff" font-family="sans-serif" font-size="56" font-weight="700">${esc(config.title)}</text>

  <!-- 설명 -->
  <text x="250" y="300" fill="#c4b5fd" font-family="sans-serif" font-size="26">${esc(config.desc)}</text>

  ${subText ? `<text x="250" y="345" fill="#e9d5ff" font-family="sans-serif" font-size="24" font-weight="500">${esc(subText)}</text>` : ''}

  <!-- 하단 CTA -->
  <rect x="100" y="520" width="260" height="52" rx="26" fill="#8A4FFF" opacity="0.9"/>
  <text x="230" y="553" fill="#ffffff" font-family="sans-serif" font-size="20" font-weight="600" text-anchor="middle">결과 확인하기</text>
</svg>`;

  return sharp(Buffer.from(svg)).png().toBuffer();
}
