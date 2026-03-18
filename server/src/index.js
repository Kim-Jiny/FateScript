import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

import { initDb } from './config/initDb.js';
import fortuneRoutes from './routes/fortune.js';
import dailyRoutes from './routes/daily.js';
import nameAnalysisRoutes from './routes/name-analysis.js';
import compatibilityRoutes from './routes/compatibility.js';
import userRoutes from './routes/user.js';
import ticketRoutes from './routes/tickets.js';
import inquiryRoutes from './routes/inquiry.js';
import adminRoutes from './routes/admin.js';
import shareRoutes from './routes/share.js';
import pool from './config/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json());

// ── 공유 페이지 렌더 ──
function renderSharePage(type, data, row) {
  const css = `*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#F6EFE5;min-height:100vh;padding:20px}
.wrap{max-width:480px;margin:0 auto}
.header{text-align:center;padding:24px 0 16px}
.header h1{font-size:20px;color:#1F2937;margin-bottom:4px}
.badge{display:inline-block;background:rgba(138,79,255,.1);color:#8A4FFF;font-size:11px;font-weight:600;padding:4px 12px;border-radius:20px;margin-top:8px}
.card{background:#fff;border-radius:16px;padding:20px;margin-bottom:16px;border:1px solid #E5E7EB}
.card h2{font-size:15px;font-weight:700;color:#1F2937;margin-bottom:12px}
.card h3{font-size:14px;font-weight:700;color:#374151;margin-bottom:8px}
.card p,.card li{font-size:13px;line-height:1.7;color:#374151}
.pillar-row{display:flex;gap:8px;margin-bottom:16px}
.pillar{flex:1;background:#F9FAFB;border-radius:12px;padding:12px 8px;text-align:center;border:1px solid #E5E7EB}
.pillar .label{font-size:10px;font-weight:600;color:#8A4FFF;margin-bottom:6px}
.pillar .hanja{font-size:22px;font-weight:700;color:#1F2937}
.pillar .hangul{font-size:11px;color:#6B7280;margin-top:2px}
.compat-btn{display:block;width:100%;padding:16px;background:#8A4FFF;color:#fff;text-align:center;border-radius:14px;font-size:15px;font-weight:700;text-decoration:none;margin:16px 0}
.footer{text-align:center;padding:24px 0}
.footer a{display:inline-block;padding:12px 24px;background:#8A4FFF;color:#fff;border-radius:12px;text-decoration:none;font-size:14px;font-weight:600}
.markdown-content h1{font-size:16px;font-weight:700;color:#1F2937;margin:16px 0 8px}
.markdown-content h2{font-size:15px;font-weight:700;color:#1F2937;margin:14px 0 8px}
.markdown-content h3{font-size:14px;font-weight:700;color:#374151;margin:12px 0 6px}
.markdown-content p{font-size:13px;line-height:1.7;color:#374151;margin-bottom:8px}
.markdown-content ul,.markdown-content ol{padding-left:20px;margin-bottom:8px}
.markdown-content li{font-size:13px;line-height:1.7;color:#374151}
.rec-card{background:#F9FAFB;border-radius:12px;padding:14px;margin-bottom:12px}
.rec-card .name{font-size:16px;font-weight:700}
.rec-card .hanja{font-size:13px;color:#6B7280}
.rec-card .score{background:rgba(138,79,255,.1);color:#8A4FFF;font-size:12px;font-weight:700;padding:3px 10px;border-radius:20px;float:right}
.rec-card .meaning{font-size:12px;color:#374151;line-height:1.5;margin-top:6px;clear:both}
.iljin-bar{background:linear-gradient(to right,#111827,#312E81);border-radius:14px;padding:12px 16px;color:#fff;display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.iljin-bar .label{font-size:12px;color:rgba(255,255,255,.7)}
.iljin-bar .value{font-size:15px;font-weight:700}
.char-card{background:#F9FAFB;border-radius:10px;padding:12px;margin-bottom:8px;display:flex;align-items:center;gap:8px}
.char-card .ch{font-size:20px;font-weight:700}
.char-card .hanja-text{font-size:14px;color:#6B7280}
.tag{display:inline-block;background:rgba(138,79,255,.1);color:#8A4FFF;font-size:11px;font-weight:600;padding:3px 8px;border-radius:6px;margin-left:4px}
.score-badge{background:rgba(138,79,255,.1);color:#8A4FFF;font-size:14px;font-weight:700;padding:4px 12px;border-radius:20px}`;

  let body = '';
  const markedScript = '<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"><\/script>';
  const renderScript = `<script>
document.querySelectorAll('[data-markdown]').forEach(function(el){
  el.innerHTML=marked.parse(el.getAttribute('data-markdown'));
  el.removeAttribute('data-markdown');
});
</script>`;

  switch (type) {
    case 'fortune': {
      const saju = data.saju || {};
      const oheng = data.oheng || {};
      const pillars = [
        { label: '년주', p: saju.yearPillar },
        { label: '월주', p: saju.monthPillar },
        { label: '일주', p: saju.dayPillar },
        { label: '시주', p: saju.hourPillar },
      ];
      const pillarHtml = pillars.map(({ label, p }) => p
        ? `<div class="pillar"><div class="label">${label}</div><div class="hanja">${p.hanja}</div><div class="hangul">${p.hangul}</div></div>`
        : `<div class="pillar"><div class="label">${label}</div><div class="hanja" style="color:#D1D5DB">?</div><div class="hangul">미상</div></div>`
      ).join('');

      // ```json 코드 펜스로 감싸진 AI 응답 정리
      let manseryeok = data.manseryeok || data.interpretation || '';
      let yearFortune = data.yearFortune || '';

      const cleaned = cleanAiContent(manseryeok);
      if (typeof cleaned === 'object') {
        manseryeok = cleaned.manseryeok || manseryeok;
        if (!yearFortune && cleaned.yearFortune) yearFortune = cleaned.yearFortune;
      } else {
        manseryeok = cleaned;
      }

      if (!yearFortune) {
        const cleanedInterp = cleanAiContent(data.interpretation || '');
        if (typeof cleanedInterp === 'object' && cleanedInterp.yearFortune) {
          yearFortune = cleanedInterp.yearFortune;
        }
      }

      // yearFortune도 코드펜스 가능성
      const cleanedYf = cleanAiContent(yearFortune);
      if (typeof cleanedYf === 'string') yearFortune = cleanedYf;

      const sections = [];
      if (manseryeok) sections.push({ emoji: '📜', title: '만세력 풀이', content: manseryeok });
      if (yearFortune) sections.push({ emoji: '🌟', title: '올해의 운세', content: yearFortune });
      if (data.categories) {
        for (const c of data.categories) {
          const cleanedContent = cleanAiContent(c.content);
          sections.push({ emoji: c.emoji, title: c.label, content: typeof cleanedContent === 'string' ? cleanedContent : c.content });
        }
      }
      const sectionHtml = sections.map(s =>
        `<div class="card"><h2>${s.emoji} ${s.title}</h2><div class="markdown-content" data-markdown="${escapeAttr(s.content)}"></div></div>`
      ).join('');

      let compatBtn = '';
      if (row.birth_date) {
        const params = new URLSearchParams({ birthDate: row.birth_date, birthTime: row.birth_time || 'unknown', gender: row.gender || '' });
        compatBtn = `<a class="compat-btn" href="https://fate.jiny.shop/compat?${params.toString()}">💑 이 사람과 궁합 보기</a>`;
      }

      body = `<div class="header"><h1>🔮 사주팔자</h1></div>
<div class="pillar-row">${pillarHtml}</div>
<div class="card"><h2>오행 분석</h2><p>${oheng.summary || ''}</p></div>
${sectionHtml}${compatBtn}`;
      break;
    }
    case 'daily': {
      body = `<div class="header"><h1>☀️ 오늘의 운세</h1><div class="badge">${data.date || ''}</div></div>
<div class="iljin-bar"><span class="label">오늘의 일진</span><span class="value">${data.iljinHanja || ''} (${data.iljinHangul || ''})</span></div>
<div class="card"><div class="markdown-content" data-markdown="${escapeAttr(data.reading || '')}"></div></div>`;
      break;
    }
    case 'compatibility': {
      body = `<div class="header"><h1>💑 궁합 분석</h1></div>
<div class="card"><div class="markdown-content" data-markdown="${escapeAttr(data.consultation || '')}"></div></div>`;
      break;
    }
    case 'name_analysis': {
      const chars = (data.characters || []).map(ch =>
        `<div class="char-card"><span class="ch">${ch.char}</span>${ch.hanja ? `<span class="hanja-text">(${ch.hanja})</span>` : ''}<span style="flex:1"></span><span class="tag">${ch.strokes}획</span><span class="tag">${ch.oheng}</span><span class="tag">${ch.yinYang}</span></div>`
      ).join('');
      const sections = [];
      if (data.ohengBalance) sections.push({ t: '오행 균형', c: data.ohengBalance });
      if (data.yinYangBalance) sections.push({ t: '음양 균형', c: data.yinYangBalance });
      if (data.sajuCompatibility) sections.push({ t: '사주 궁합', c: data.sajuCompatibility });
      if (data.advice) sections.push({ t: '운명선생의 조언', c: data.advice });
      const sHtml = sections.map(s => `<h3>${s.t}</h3><div class="markdown-content" data-markdown="${escapeAttr(s.c)}"></div>`).join('');

      body = `<div class="header"><h1>📝 이름 분석</h1><div class="badge score-badge">${data.overallScore || 0}점</div></div>
<div class="card">${chars}${sHtml}</div>`;
      break;
    }
    case 'name_recommend': {
      const recs = (data.recommendations || []).map(r =>
        `<div class="rec-card"><span class="score">${r.score}점</span><span class="name">${r.name}</span> <span class="hanja">(${r.hanja})</span><div class="meaning">${r.meaning}<br><small style="color:#6B7280">${r.sajuFit}</small></div></div>`
      ).join('');
      const adviceHtml = data.advice ? `<h3>운명선생의 조언</h3><div class="markdown-content" data-markdown="${escapeAttr(data.advice)}"></div>` : '';
      const criteriaHtml = data.selectionCriteria ? `<h3>선정 기준</h3><div class="markdown-content" data-markdown="${escapeAttr(data.selectionCriteria)}"></div>` : '';

      body = `<div class="header"><h1>✨ 이름 추천</h1></div>
<div class="card">${recs}${criteriaHtml}${adviceHtml}</div>`;
      break;
    }
    default:
      body = '<div class="card"><p>지원하지 않는 결과 유형입니다.</p></div>';
  }

  const titleMap = { fortune: '사주팔자', daily: '오늘의 운세', compatibility: '궁합 분석', name_analysis: '이름 분석', name_recommend: '이름 추천' };

  return `<!DOCTYPE html>
<html lang="ko"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta property="og:title" content="운명일기 - ${titleMap[type] || '결과'}">
<meta property="og:description" content="AI 사주 분석 결과를 확인해 보세요.">
<title>운명일기 - ${titleMap[type] || '결과'}</title>
<style>${css}</style>
</head><body>
<div class="wrap">${body}
<div class="footer"><a href="https://apps.apple.com/app/id0000000000">운명일기 앱에서 보기</a></div>
</div>
${markedScript}${renderScript}
</body></html>`;
}

function escapeAttr(str) {
  return (str || '').replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// AI 응답에서 ```json 코드 펜스를 제거하고 내부 JSON을 파싱하여 실제 마크다운 텍스트 추출
function cleanAiContent(str) {
  if (!str || typeof str !== 'string') return str || '';
  const fenceMatch = str.match(/^```(?:json)?\s*\n?([\s\S]*?)\n?```\s*$/);
  if (!fenceMatch) return str;
  const inner = fenceMatch[1];
  try {
    const parsed = JSON.parse(inner);
    // { manseryeok: "...", yearFortune: "..." } 형태
    if (typeof parsed === 'object' && parsed !== null) return parsed;
    return String(parsed);
  } catch {
    return inner;
  }
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'unmyeongilgi-server',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/fortune', fortuneRoutes);
app.use('/api/daily', dailyRoutes);
app.use('/api/name-analysis', nameAnalysisRoutes);
app.use('/api/compatibility', compatibilityRoutes);
app.use('/api/user', userRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/inquiry', inquiryRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/share', shareRoutes);

// .well-known 파일에 Content-Type: application/json 보장
app.use('/.well-known', express.static(path.join(__dirname, '..', 'public', '.well-known'), {
  setHeaders: (res) => {
    res.setHeader('Content-Type', 'application/json');
  },
}));

// /ref/:code 랜딩 페이지
app.get('/ref/:code', (req, res) => {
  const code = req.params.code;
  res.send(`<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>운명일기 - 추천 초대</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#F6EFE5;min-height:100vh;display:flex;align-items:center;justify-content:center}
.card{background:#fff;border-radius:24px;padding:40px 28px;max-width:380px;width:90%;text-align:center;box-shadow:0 4px 24px rgba(0,0,0,.08)}
.icon{font-size:48px;margin-bottom:16px}
h1{font-size:22px;color:#1F2937;margin-bottom:8px}
.desc{font-size:14px;color:#6B7280;line-height:1.6;margin-bottom:24px}
.code-box{background:rgba(138,79,255,.08);border-radius:12px;padding:14px;margin-bottom:28px}
.code-label{font-size:12px;color:#9CA3AF;margin-bottom:4px}
.code{font-size:24px;font-weight:800;color:#8A4FFF;letter-spacing:3px}
.btn{display:block;width:100%;padding:16px;border-radius:14px;font-size:15px;font-weight:700;text-decoration:none;margin-bottom:10px;color:#fff}
.btn-ios{background:#8A4FFF}
.btn-android{background:#1F2937}
.footer{font-size:11px;color:#9CA3AF;margin-top:16px}
</style>
</head>
<body>
<div class="card">
  <div class="icon">&#x1F52E;</div>
  <h1>운명일기에 초대합니다</h1>
  <p class="desc">AI 사주 분석으로 오늘의 운세를 확인하세요.<br>추천 코드를 입력하면 양쪽 모두 티켓 3장!</p>
  <div class="code-box">
    <div class="code-label">추천 코드</div>
    <div class="code">${code}</div>
  </div>
  <a class="btn btn-ios" href="https://apps.apple.com/app/id0000000000">App Store에서 다운로드</a>
  <a class="btn btn-android" href="https://play.google.com/store/apps/details?id=com.unmyeongilgi.unmyeongilgi">Google Play에서 다운로드</a>
  <p class="footer">앱 설치 후 사주 정보 입력 시 추천 코드를 입력하세요.</p>
</div>
<script>
(function(){
  var ua=navigator.userAgent||'';
  if(/iPhone|iPad|iPod/i.test(ua)){
    setTimeout(function(){location.href='https://apps.apple.com/app/id0000000000';},2000);
  }else if(/Android/i.test(ua)){
    setTimeout(function(){location.href='https://play.google.com/store/apps/details?id=com.unmyeongilgi.unmyeongilgi';},2000);
  }
})();
</script>
</body>
</html>`);
});

// ── 공유 결과 웹 페이지 ──
app.get('/s/:id', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM shared_results WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).send('결과를 찾을 수 없습니다.');
    const row = rows[0];
    const data = typeof row.data === 'string' ? JSON.parse(row.data) : row.data;
    res.send(renderSharePage(row.type, data, row));
  } catch (err) {
    console.error('share page error:', err);
    res.status(500).send('페이지를 불러올 수 없습니다.');
  }
});

// ── 궁합 보기 랜딩 페이지 ──
app.get('/compat', (req, res) => {
  const { birthDate, birthTime, gender } = req.query;
  const deepLink = `https://fate.jiny.shop/compat?birthDate=${encodeURIComponent(birthDate || '')}&birthTime=${encodeURIComponent(birthTime || '')}&gender=${encodeURIComponent(gender || '')}`;
  res.send(`<!DOCTYPE html>
<html lang="ko"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>운명일기 - 궁합 보기</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#F6EFE5;min-height:100vh;display:flex;align-items:center;justify-content:center}
.card{background:#fff;border-radius:24px;padding:40px 28px;max-width:380px;width:90%;text-align:center;box-shadow:0 4px 24px rgba(0,0,0,.08)}
.icon{font-size:48px;margin-bottom:16px}
h1{font-size:22px;color:#1F2937;margin-bottom:8px}
.desc{font-size:14px;color:#6B7280;line-height:1.6;margin-bottom:24px}
.btn{display:block;width:100%;padding:16px;border-radius:14px;font-size:15px;font-weight:700;text-decoration:none;margin-bottom:10px;color:#fff}
.btn-primary{background:#8A4FFF}
.btn-ios{background:#1F2937}
.btn-android{background:#34D399;color:#1F2937}
.footer{font-size:11px;color:#9CA3AF;margin-top:16px}
</style>
</head><body>
<div class="card">
  <div class="icon">&#x1F491;</div>
  <h1>궁합 보기</h1>
  <p class="desc">운명일기 앱에서 상대방과의 궁합을 확인해 보세요!</p>
  <a class="btn btn-ios" href="https://apps.apple.com/app/id0000000000">App Store에서 다운로드</a>
  <a class="btn btn-android" href="https://play.google.com/store/apps/details?id=com.unmyeongilgi.unmyeongilgi">Google Play에서 다운로드</a>
  <p class="footer">앱이 설치되어 있다면 자동으로 열립니다.</p>
</div>
<script>
(function(){
  var ua=navigator.userAgent||'';
  // 앱 딥링크 시도
  if(/iPhone|iPad|iPod/i.test(ua)){
    setTimeout(function(){location.href='https://apps.apple.com/app/id0000000000';},2500);
  }else if(/Android/i.test(ua)){
    setTimeout(function(){location.href='https://play.google.com/store/apps/details?id=com.unmyeongilgi.unmyeongilgi';},2500);
  }
})();
</script>
</body></html>`);
});

app.use(express.static(path.join(__dirname, '..', 'public')));

await initDb();

app.listen(port, '0.0.0.0', () => {
  console.log(`Unmyeong Diary server listening on 0.0.0.0:${port}`);
});
