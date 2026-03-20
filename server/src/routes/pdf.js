import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';

const router = Router();

/**
 * POST /api/pdf/generate
 * body: { type, data }
 * 결과를 인쇄용 HTML로 변환하여 반환
 * 클라이언트에서 share_plus로 공유 or 저장
 */
router.post('/generate', optionalAuth, async (req, res) => {
  try {
    const { type, data } = req.body ?? {};

    if (!type || !data) {
      return res.status(400).json({ error: 'type과 data는 필수입니다.' });
    }

    const html = generatePrintableHtml(type, data);

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  } catch (err) {
    console.error('PDF generate error:', err);
    res.status(500).json({ error: 'PDF 생성 중 오류가 발생했습니다.' });
  }
});

function generatePrintableHtml(type, data) {
  const titleMap = {
    fortune: '사주팔자 분석 리포트',
    daily: '오늘의 운세 리포트',
    compatibility: '궁합 분석 리포트',
    name_analysis: '이름 분석 리포트',
    name_recommend: '이름 추천 리포트',
  };
  const title = titleMap[type] || '분석 리포트';

  let body = '';

  switch (type) {
    case 'fortune':
      body = `<h2>만세력 풀이</h2><div class="content">${data.manseryeok || data.interpretation || ''}</div>`;
      if (data.yearFortune) body += `<h2>올해의 운세</h2><div class="content">${data.yearFortune}</div>`;
      if (data.categories) {
        for (const c of data.categories) {
          body += `<h2>${c.emoji || ''} ${c.label}</h2><div class="content">${c.content}</div>`;
        }
      }
      break;
    case 'daily':
      body = `<p><strong>날짜:</strong> ${data.date || ''}</p>
<p><strong>일진:</strong> ${data.iljinHanja || ''} (${data.iljinHangul || ''})</p>
<div class="content">${data.reading || ''}</div>`;
      break;
    case 'compatibility':
      body = `<div class="content">${data.consultation || ''}</div>`;
      break;
    case 'name_analysis':
      body = `<p><strong>종합 점수:</strong> ${data.overallScore || 0}점</p>
<div class="content">${data.ohengBalance || ''}</div>
<div class="content">${data.sajuCompatibility || ''}</div>
<div class="content">${data.advice || ''}</div>`;
      break;
    default:
      body = '<p>지원하지 않는 유형입니다.</p>';
  }

  return `<!DOCTYPE html>
<html lang="ko"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>운명일기 - ${title}</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;600;700&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Noto Sans KR',sans-serif;padding:40px 32px;max-width:800px;margin:0 auto;color:#1F2937;line-height:1.8}
h1{font-size:24px;text-align:center;margin-bottom:8px;color:#8A4FFF}
.subtitle{text-align:center;color:#6B7280;font-size:13px;margin-bottom:32px}
h2{font-size:16px;margin-top:24px;margin-bottom:8px;padding-bottom:6px;border-bottom:2px solid #8A4FFF;color:#1F2937}
.content{font-size:14px;white-space:pre-wrap}
.content p{margin-bottom:8px}
@media print{body{padding:20px}}
</style>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"><\/script>
</head><body>
<h1>${title}</h1>
<p class="subtitle">운명일기 — AI 사주 분석</p>
${body}
<script>
document.querySelectorAll('.content').forEach(function(el){
  el.innerHTML=marked.parse(el.textContent);
});
</script>
</body></html>`;
}

export default router;
