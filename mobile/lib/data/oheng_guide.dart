class OhengGuideItem {
  final String element;
  final String emoji;
  final String color;
  final String colorHex;
  final String food;
  final String direction;
  final String activity;
  final String season;
  final String numbers;

  const OhengGuideItem({
    required this.element,
    required this.emoji,
    required this.color,
    required this.colorHex,
    required this.food,
    required this.direction,
    required this.activity,
    required this.season,
    required this.numbers,
  });
}

const ohengGuideData = <String, OhengGuideItem>{
  '목': OhengGuideItem(
    element: '목 (Wood)',
    emoji: '🌳',
    color: '초록색, 청색',
    colorHex: '#22C55E',
    food: '녹색 채소, 신맛 음식 (레몬, 매실)',
    direction: '동쪽',
    activity: '산책, 등산, 원예, 요가',
    season: '봄',
    numbers: '3, 8',
  ),
  '화': OhengGuideItem(
    element: '화 (Fire)',
    emoji: '🔥',
    color: '빨간색, 분홍색',
    colorHex: '#EF4444',
    food: '쓴맛 음식 (커피, 다크초콜릿, 녹차)',
    direction: '남쪽',
    activity: '달리기, 댄스, 요리, 열정적 취미',
    season: '여름',
    numbers: '2, 7',
  ),
  '토': OhengGuideItem(
    element: '토 (Earth)',
    emoji: '⛰️',
    color: '노란색, 갈색, 베이지',
    colorHex: '#F59E0B',
    food: '단맛 음식 (고구마, 꿀, 대추)',
    direction: '중앙',
    activity: '명상, 독서, 도자기, 텃밭가꾸기',
    season: '환절기 (계절 전환기)',
    numbers: '5, 10',
  ),
  '금': OhengGuideItem(
    element: '금 (Metal)',
    emoji: '⚙️',
    color: '흰색, 금색, 은색',
    colorHex: '#9CA3AF',
    food: '매운맛 음식 (고추, 생강, 마늘)',
    direction: '서쪽',
    activity: '악기 연주, 정리정돈, 공예',
    season: '가을',
    numbers: '4, 9',
  ),
  '수': OhengGuideItem(
    element: '수 (Water)',
    emoji: '💧',
    color: '검은색, 파란색, 남색',
    colorHex: '#3B82F6',
    food: '짠맛 음식 (미역, 해산물, 된장)',
    direction: '북쪽',
    activity: '수영, 반신욕, 명상, 글쓰기',
    season: '겨울',
    numbers: '1, 6',
  ),
};
