import sharp from 'sharp';

const TYPE_CONFIG = {
  fortune:        { color1: '#6d28d9', color2: '#4c1d95', accent: '#a78bfa' },
  daily:          { color1: '#7c3aed', color2: '#4338ca', accent: '#c4b5fd' },
  compatibility:  { color1: '#7e22ce', color2: '#581c87', accent: '#d8b4fe' },
  name_analysis:  { color1: '#6d28d9', color2: '#312e81', accent: '#a78bfa' },
  name_recommend: { color1: '#7c3aed', color2: '#3b0764', accent: '#c084fc' },
};

/**
 * 공유 결과의 OG 이미지 생성 (1200x630 PNG)
 * 텍스트 없이 도형만으로 브랜딩
 */
export async function generateOgImage(type) {
  const config = TYPE_CONFIG[type] || TYPE_CONFIG.fortune;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${config.color1}"/>
      <stop offset="100%" stop-color="${config.color2}"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="45%" r="40%">
      <stop offset="0%" stop-color="${config.accent}" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="${config.accent}" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect width="1200" height="630" fill="url(#glow)"/>

  <!-- 장식 원 -->
  <circle cx="1000" cy="80" r="180" fill="${config.accent}" opacity="0.04"/>
  <circle cx="200" cy="550" r="120" fill="${config.accent}" opacity="0.04"/>

  <!-- 중앙 심볼 -->
  <circle cx="600" cy="280" r="100" fill="none" stroke="${config.accent}" stroke-width="2" opacity="0.2"/>
  <circle cx="600" cy="280" r="70" fill="none" stroke="${config.accent}" stroke-width="1.5" opacity="0.15"/>
  <circle cx="600" cy="280" r="8" fill="${config.accent}" opacity="0.6"/>

  <!-- 4개의 작은 점 (사주 4기둥 상징) -->
  <circle cx="540" cy="280" r="5" fill="${config.accent}" opacity="0.4"/>
  <circle cx="575" cy="240" r="5" fill="${config.accent}" opacity="0.4"/>
  <circle cx="625" cy="240" r="5" fill="${config.accent}" opacity="0.4"/>
  <circle cx="660" cy="280" r="5" fill="${config.accent}" opacity="0.4"/>

  <!-- 연결선 -->
  <line x1="540" y1="280" x2="575" y2="240" stroke="${config.accent}" stroke-width="1" opacity="0.15"/>
  <line x1="575" y1="240" x2="600" y2="280" stroke="${config.accent}" stroke-width="1" opacity="0.15"/>
  <line x1="600" y1="280" x2="625" y2="240" stroke="${config.accent}" stroke-width="1" opacity="0.15"/>
  <line x1="625" y1="240" x2="660" y2="280" stroke="${config.accent}" stroke-width="1" opacity="0.15"/>

  <!-- 상단 가로선 -->
  <rect x="460" y="160" width="280" height="1" fill="${config.accent}" opacity="0.12"/>

  <!-- 하단 악센트 바 -->
  <rect x="550" y="400" width="100" height="4" rx="2" fill="${config.accent}" opacity="0.5"/>

  <!-- 하단 장식 점들 -->
  <circle cx="560" cy="430" r="2" fill="${config.accent}" opacity="0.2"/>
  <circle cx="580" cy="430" r="2" fill="${config.accent}" opacity="0.3"/>
  <circle cx="600" cy="430" r="2" fill="${config.accent}" opacity="0.4"/>
  <circle cx="620" cy="430" r="2" fill="${config.accent}" opacity="0.3"/>
  <circle cx="640" cy="430" r="2" fill="${config.accent}" opacity="0.2"/>
</svg>`;

  return sharp(Buffer.from(svg)).png().toBuffer();
}
