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
import { generateOgImage } from './utils/ogImage.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json({ limit: '5mb' }));

// ── 공유 페이지 렌더 ──
function renderSharePage(type, data, row, shareId) {
  const css = `@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Noto Sans KR',sans-serif;background:#0f0a1e;min-height:100vh;color:#e2d8f0;overflow-x:hidden}
body::before{content:'';position:fixed;top:-50%;left:-50%;width:200%;height:200%;background:radial-gradient(circle at 30% 20%,rgba(138,79,255,.12) 0%,transparent 50%),radial-gradient(circle at 70% 80%,rgba(99,102,241,.08) 0%,transparent 50%);pointer-events:none;z-index:0}
.wrap{max-width:520px;margin:0 auto;padding:0 20px 40px;position:relative;z-index:1}
.hero{text-align:center;padding:48px 0 32px;position:relative}
.hero::after{content:'';position:absolute;bottom:0;left:50%;transform:translateX(-50%);width:60px;height:3px;background:linear-gradient(90deg,#8A4FFF,#c084fc);border-radius:2px}
.hero .icon{font-size:48px;margin-bottom:16px;display:block;filter:drop-shadow(0 4px 20px rgba(138,79,255,.4))}
.hero h1{font-size:24px;font-weight:800;background:linear-gradient(135deg,#fff,#c4b5fd);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:6px;letter-spacing:-.5px}
.hero .sub{font-size:13px;color:rgba(196,181,253,.7);font-weight:400}
.badge{display:inline-block;background:rgba(138,79,255,.15);color:#c4b5fd;font-size:12px;font-weight:600;padding:6px 16px;border-radius:24px;margin-top:12px;border:1px solid rgba(138,79,255,.2);backdrop-filter:blur(8px)}
.card{background:rgba(255,255,255,.04);border-radius:20px;padding:24px;margin-bottom:16px;border:1px solid rgba(255,255,255,.06);backdrop-filter:blur(12px);transition:transform .2s}
.card:hover{transform:translateY(-2px)}
.card h2{font-size:16px;font-weight:700;color:#e9d5ff;margin-bottom:14px;display:flex;align-items:center;gap:8px}
.card h3{font-size:14px;font-weight:700;color:#c4b5fd;margin:16px 0 8px;padding-left:12px;border-left:3px solid #8A4FFF}
.card p,.card li{font-size:13px;line-height:1.8;color:rgba(226,216,240,.85)}
.pillar-row{display:flex;gap:10px;margin-bottom:20px}
.pillar{flex:1;border-radius:16px;text-align:center;overflow:hidden;border:1px solid rgba(255,255,255,.08)}
.pillar .label{font-size:10px;font-weight:700;color:#a78bfa;letter-spacing:1px;padding:10px 8px 6px;background:rgba(138,79,255,.06)}
.pillar .stem,.pillar .branch{padding:10px 8px}
.pillar .stem{border-bottom:1px solid rgba(255,255,255,.06)}
.pillar .char{font-size:26px;font-weight:800;line-height:1.2}
.pillar .reading{font-size:10px;margin-top:2px;opacity:.6}
.oheng-section{background:rgba(255,255,255,.04);border-radius:20px;padding:24px;margin-bottom:16px;border:1px solid rgba(255,255,255,.06)}
.oheng-section h2{font-size:16px;font-weight:700;color:#e9d5ff;margin-bottom:16px}
.oheng-bars{display:flex;flex-direction:column;gap:10px;margin-bottom:16px}
.oheng-row{display:flex;align-items:center;gap:10px}
.oheng-row .el-label{min-width:54px;font-size:12px;font-weight:600;display:flex;align-items:center;gap:4px}
.oheng-row .el-dot{width:8px;height:8px;border-radius:50%;display:inline-block}
.oheng-row .bar-wrap{flex:1;height:12px;background:rgba(255,255,255,.06);border-radius:6px;overflow:hidden}
.oheng-row .bar-fill{height:100%;border-radius:6px;transition:width .8s ease}
.oheng-row .el-count{min-width:20px;text-align:right;font-size:12px;font-weight:700;color:rgba(226,216,240,.8)}
.oheng-tags{display:flex;gap:10px;flex-wrap:wrap}
.oheng-tag{display:flex;align-items:center;gap:6px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:8px 14px;font-size:12px}
.oheng-tag .tag-emoji{font-size:16px}
.oheng-tag .tag-label{color:rgba(196,181,253,.6);font-weight:500}
.oheng-tag .tag-value{font-weight:700;color:#e9d5ff}
.oheng-summary{margin-top:14px;font-size:13px;line-height:1.8;color:rgba(226,216,240,.7)}
.iljin-bar{background:linear-gradient(135deg,#1e1145,#312E81,#4338ca);border-radius:16px;padding:16px 20px;display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;border:1px solid rgba(138,79,255,.2);box-shadow:0 4px 24px rgba(99,102,241,.15)}
.iljin-bar .label{font-size:12px;color:rgba(255,255,255,.5);font-weight:500}
.iljin-bar .value{font-size:17px;font-weight:800;background:linear-gradient(135deg,#fff,#c4b5fd);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.compat-btn{display:block;width:100%;padding:18px;background:linear-gradient(135deg,#8A4FFF,#6d28d9);color:#fff;text-align:center;border-radius:16px;font-size:16px;font-weight:700;text-decoration:none;margin:20px 0;box-shadow:0 4px 24px rgba(138,79,255,.3);transition:all .2s;letter-spacing:-.3px}
.compat-btn:hover{transform:translateY(-2px);box-shadow:0 8px 32px rgba(138,79,255,.4)}
.char-card{background:rgba(255,255,255,.04);border-radius:14px;padding:14px 16px;margin-bottom:10px;display:flex;align-items:center;gap:10px;border:1px solid rgba(255,255,255,.06)}
.char-card .ch{font-size:24px;font-weight:800;color:#fff;min-width:32px;text-align:center}
.char-card .hanja-text{font-size:14px;color:rgba(196,181,253,.6)}
.tag{display:inline-block;background:rgba(138,79,255,.12);color:#a78bfa;font-size:11px;font-weight:600;padding:4px 10px;border-radius:8px;margin-left:4px;border:1px solid rgba(138,79,255,.15)}
.score-badge{font-size:20px;font-weight:800;color:#c084fc}
.rec-card{background:rgba(255,255,255,.04);border-radius:16px;padding:18px;margin-bottom:14px;border:1px solid rgba(255,255,255,.06);transition:transform .2s}
.rec-card:hover{transform:translateY(-2px)}
.rec-card .name{font-size:18px;font-weight:800;color:#fff}
.rec-card .hanja{font-size:13px;color:rgba(196,181,253,.6)}
.rec-card .score{background:linear-gradient(135deg,rgba(138,79,255,.2),rgba(192,132,252,.15));color:#c084fc;font-size:13px;font-weight:700;padding:4px 12px;border-radius:20px;float:right;border:1px solid rgba(138,79,255,.2)}
.rec-card .meaning{font-size:12px;color:rgba(226,216,240,.7);line-height:1.6;margin-top:8px;clear:both}
.markdown-content h1{font-size:16px;font-weight:700;color:#e9d5ff;margin:18px 0 8px}
.markdown-content h2{font-size:15px;font-weight:700;color:#e9d5ff;margin:16px 0 8px}
.markdown-content h3{font-size:14px;font-weight:700;color:#c4b5fd;margin:14px 0 6px}
.markdown-content p{font-size:13px;line-height:1.8;color:rgba(226,216,240,.85);margin-bottom:10px}
.markdown-content ul,.markdown-content ol{padding-left:20px;margin-bottom:10px}
.markdown-content li{font-size:13px;line-height:1.8;color:rgba(226,216,240,.85)}
.markdown-content strong{color:#e9d5ff}
.footer{text-align:center;padding:32px 0 16px}
.footer p{font-size:11px;color:rgba(196,181,253,.4);margin-bottom:16px}
.footer a{display:inline-block;padding:14px 32px;background:linear-gradient(135deg,#8A4FFF,#6d28d9);color:#fff;border-radius:14px;text-decoration:none;font-size:15px;font-weight:700;box-shadow:0 4px 24px rgba(138,79,255,.3);transition:all .2s;letter-spacing:-.3px}
.footer a:hover{transform:translateY(-2px);box-shadow:0 8px 32px rgba(138,79,255,.4)}
.divider{height:1px;background:linear-gradient(90deg,transparent,rgba(138,79,255,.2),transparent);margin:8px 0}
@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
.card,.pillar,.iljin-bar,.oheng-section,.rec-card,.char-card{animation:fadeUp .5s ease-out both}
.card:nth-child(2){animation-delay:.1s}.card:nth-child(3){animation-delay:.2s}.card:nth-child(4){animation-delay:.3s}`;

  let body = '';
  const markedScript = '<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"><\/script>';
  const renderScript = `<script>
document.querySelectorAll('[data-markdown]').forEach(function(el){
  el.innerHTML=marked.parse(el.getAttribute('data-markdown'));
  el.removeAttribute('data-markdown');
});
</script>`;

  const heroMap = {
    fortune:        { icon: '🔮', title: '사주팔자', sub: 'AI 사주 분석 결과' },
    daily:          { icon: '☀️', title: '오늘의 운세', sub: '오늘 하루를 밝히는 운세' },
    compatibility:  { icon: '💑', title: '궁합 분석', sub: 'AI 궁합 분석 결과' },
    name_analysis:  { icon: '📝', title: '이름 분석', sub: 'AI 성명학 분석' },
    name_recommend: { icon: '✨', title: '이름 추천', sub: 'AI 성명학 작명' },
  };
  const hero = heroMap[type] || heroMap.fortune;

  // 천간/지지 → 오행 매핑 (사주 기둥 색상용)
  const stemEl = { '갑':'목','을':'목','병':'화','정':'화','무':'토','기':'토','경':'금','신':'금','임':'수','계':'수' };
  const branchEl = { '인':'목','묘':'목','사':'화','오':'화','진':'토','술':'토','축':'토','미':'토','신':'금','유':'금','해':'수','자':'수' };
  const elColor = { '목':'#22C55E','화':'#EF4444','토':'#F59E0B','금':'#9CA3AF','수':'#3B82F6' };
  const elBg = { '목':'rgba(34,197,94,.12)','화':'rgba(239,68,68,.12)','토':'rgba(245,158,11,.12)','금':'rgba(156,163,175,.12)','수':'rgba(59,130,246,.12)' };

  switch (type) {
    case 'fortune': {
      const saju = data.saju || {};
      const oheng = data.oheng || {};

      // ── 사주 기둥 (천간/지지 분리, 오행 색상) ──
      const pillars = [
        { label: '년주', p: saju.yearPillar },
        { label: '월주', p: saju.monthPillar },
        { label: '일주', p: saju.dayPillar },
        { label: '시주', p: saju.hourPillar },
      ];
      const pillarHtml = pillars.map(({ label, p }) => {
        if (!p) return `<div class="pillar"><div class="label">${label}</div><div class="stem" style="background:rgba(255,255,255,.02)"><div class="char" style="color:rgba(255,255,255,.15)">?</div></div><div class="branch" style="background:rgba(255,255,255,.02)"><div class="char" style="color:rgba(255,255,255,.15)">?</div><div class="reading">미상</div></div></div>`;
        const stemChar = p.hangul[0], branchChar = p.hangul[p.hangul.length > 1 ? 1 : 0];
        const stemHanja = p.hanja[0], branchHanja = p.hanja[p.hanja.length > 1 ? 1 : 0];
        const sEl = stemEl[stemChar] || '토', bEl = branchEl[branchChar] || '토';
        const sC = elColor[sEl], bC = elColor[bEl];
        const sBg = elBg[sEl], bBg = elBg[bEl];
        return `<div class="pillar"><div class="label">${label}</div><div class="stem" style="background:${sBg}"><div class="char" style="color:${sC}">${stemHanja}</div><div class="reading" style="color:${sC}">${stemChar}</div></div><div class="branch" style="background:${bBg}"><div class="char" style="color:${bC}">${branchHanja}</div><div class="reading" style="color:${bC}">${branchChar}</div></div></div>`;
      }).join('');

      // ── 오행 분석 (바 차트 + 강/약 태그 + 요약) ──
      const dist = oheng.distribution || {};
      const dominant = oheng.dominant || {};
      const weak = oheng.weak || {};
      const total = Object.values(dist).reduce((a, b) => a + b, 0) || 1;
      const elOrder = ['목','화','토','금','수'];
      const elName = { '목':'Wood','화':'Fire','토':'Earth','금':'Metal','수':'Water' };
      const barsHtml = elOrder.map(el => {
        const count = dist[el] || 0;
        const pct = Math.round((count / total) * 100);
        const c = elColor[el];
        return `<div class="oheng-row"><span class="el-label"><span class="el-dot" style="background:${c}"></span>${el} ${elName[el]}</span><div class="bar-wrap"><div class="bar-fill" style="width:${pct}%;background:${c}"></div></div><span class="el-count">${count}</span></div>`;
      }).join('');

      const tagsHtml = `<div class="oheng-tags">`
        + (dominant.name ? `<div class="oheng-tag"><span class="tag-emoji">${dominant.emoji || '🔥'}</span><span class="tag-label">가장 강한</span><span class="tag-value">${dominant.name}</span></div>` : '')
        + (weak.name ? `<div class="oheng-tag"><span class="tag-emoji">${weak.emoji || '💧'}</span><span class="tag-label">가장 약한</span><span class="tag-value">${weak.name}</span></div>` : '')
        + `</div>`;

      const ohengHtml = `<div class="oheng-section"><h2>⚖️ 오행 분석</h2><div class="oheng-bars">${barsHtml}</div>${tagsHtml}${oheng.summary ? `<p class="oheng-summary">${oheng.summary}</p>` : ''}</div>`;

      // ── 만세력 / 카테고리 ──
      let manseryeok = data.manseryeok || data.interpretation || '';
      let yearFortune = data.yearFortune || '';
      const cleaned = cleanAiContent(manseryeok);
      if (typeof cleaned === 'object') {
        manseryeok = cleaned.manseryeok || manseryeok;
        if (!yearFortune && cleaned.yearFortune) yearFortune = cleaned.yearFortune;
      } else { manseryeok = cleaned; }
      if (!yearFortune) {
        const cleanedInterp = cleanAiContent(data.interpretation || '');
        if (typeof cleanedInterp === 'object' && cleanedInterp.yearFortune) yearFortune = cleanedInterp.yearFortune;
      }
      const cleanedYf = cleanAiContent(yearFortune);
      if (typeof cleanedYf === 'string') yearFortune = cleanedYf;

      const sections = [];
      if (manseryeok) sections.push({ emoji: '📜', title: '만세력 풀이', content: manseryeok });
      if (yearFortune) sections.push({ emoji: '🌟', title: '올해의 운세', content: yearFortune });
      if (data.categories) {
        for (const c of data.categories) {
          const cc = cleanAiContent(c.content);
          sections.push({ emoji: c.emoji, title: c.label, content: typeof cc === 'string' ? cc : c.content });
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

      body = `<div class="hero"><span class="icon">${hero.icon}</span><h1>${hero.title}</h1><p class="sub">${hero.sub}</p></div>
<div class="pillar-row">${pillarHtml}</div>
${ohengHtml}
<div class="divider"></div>
${sectionHtml}${compatBtn}`;
      break;
    }
    case 'daily': {
      body = `<div class="hero"><span class="icon">${hero.icon}</span><h1>${hero.title}</h1><p class="sub">${hero.sub}</p><div class="badge">${data.date || ''}</div></div>
<div class="iljin-bar"><span class="label">오늘의 일진</span><span class="value">${data.iljinHanja || ''} (${data.iljinHangul || ''})</span></div>
<div class="card"><div class="markdown-content" data-markdown="${escapeAttr(data.reading || '')}"></div></div>`;
      break;
    }
    case 'compatibility': {
      body = `<div class="hero"><span class="icon">${hero.icon}</span><h1>${hero.title}</h1><p class="sub">${hero.sub}</p></div>
<div class="card"><div class="markdown-content" data-markdown="${escapeAttr(data.consultation || '')}"></div></div>`;
      break;
    }
    case 'name_analysis': {
      const chars = (data.characters || []).map(ch =>
        `<div class="char-card"><span class="ch">${ch.char}</span>${ch.hanja ? `<span class="hanja-text">(${ch.hanja})</span>` : ''}<span style="flex:1"></span><span class="tag">${ch.strokes}획</span><span class="tag">${ch.oheng}</span><span class="tag">${ch.yinYang}</span></div>`
      ).join('');
      const sections = [];
      if (data.ohengBalance) sections.push({ t: '⚖️ 오행 균형', c: data.ohengBalance });
      if (data.yinYangBalance) sections.push({ t: '☯️ 음양 균형', c: data.yinYangBalance });
      if (data.sajuCompatibility) sections.push({ t: '🔮 사주 궁합', c: data.sajuCompatibility });
      if (data.advice) sections.push({ t: '🍀 운명선생의 조언', c: data.advice });
      const sHtml = sections.map(s => `<h3>${s.t}</h3><div class="markdown-content" data-markdown="${escapeAttr(s.c)}"></div>`).join('');

      body = `<div class="hero"><span class="icon">${hero.icon}</span><h1>${hero.title}</h1><p class="sub">${hero.sub}</p><div class="score-badge" style="margin-top:12px">${data.overallScore || 0}점</div></div>
<div class="card">${chars}<div class="divider" style="margin:16px 0"></div>${sHtml}</div>`;
      break;
    }
    case 'name_recommend': {
      const recs = (data.recommendations || []).map(r =>
        `<div class="rec-card"><span class="score">${r.score}점</span><span class="name">${r.name}</span> <span class="hanja">(${r.hanja})</span><div class="meaning">${r.meaning}<br><small style="color:rgba(196,181,253,.5)">${r.sajuFit}</small></div></div>`
      ).join('');
      const adviceHtml = data.advice ? `<h3>🍀 운명선생의 조언</h3><div class="markdown-content" data-markdown="${escapeAttr(data.advice)}"></div>` : '';
      const criteriaHtml = data.selectionCriteria ? `<h3>📋 선정 기준</h3><div class="markdown-content" data-markdown="${escapeAttr(data.selectionCriteria)}"></div>` : '';

      body = `<div class="hero"><span class="icon">${hero.icon}</span><h1>${hero.title}</h1><p class="sub">${hero.sub}</p></div>
<div class="card">${recs}<div class="divider" style="margin:16px 0"></div>${criteriaHtml}${adviceHtml}</div>`;
      break;
    }
    default:
      body = '<div class="card"><p>지원하지 않는 결과 유형입니다.</p></div>';
  }

  const titleMap = { fortune: '사주팔자', daily: '오늘의 운세', compatibility: '궁합 분석', name_analysis: '이름 분석', name_recommend: '이름 추천' };
  const descMap = { fortune: 'AI가 분석한 사주팔자 결과입니다.', daily: 'AI가 분석한 오늘의 운세입니다.', compatibility: 'AI가 분석한 궁합 결과입니다.', name_analysis: 'AI 성명학 이름 분석 결과입니다.', name_recommend: 'AI 성명학 이름 추천 결과입니다.' };

  return `<!DOCTYPE html>
<html lang="ko"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta property="og:title" content="운명일기 - ${titleMap[type] || '결과'}">
<meta property="og:description" content="${descMap[type] || 'AI 사주 분석 결과를 확인해 보세요.'}">
<meta property="og:image" content="https://fate.jiny.shop/og/${shareId}.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:type" content="website">
<meta property="og:url" content="https://fate.jiny.shop/s/${shareId}">
<meta name="twitter:card" content="summary_large_image">
<title>운명일기 - ${titleMap[type] || '결과'}</title>
<style>${css}</style>
</head><body>
<div class="wrap">${body}
<div class="footer"><p>운명일기 — AI 사주 분석</p><a href="https://apps.apple.com/app/id0000000000">✨ 나도 운세 보기</a></div>
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
    res.send(renderSharePage(row.type, data, row, req.params.id));
  } catch (err) {
    console.error('share page error:', err);
    res.status(500).send('페이지를 불러올 수 없습니다.');
  }
});

// ── OG 이미지 생성 ──
app.get('/og/:id.png', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT type, data FROM shared_results WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).send('Not found');
    const row = rows[0];
    const data = typeof row.data === 'string' ? JSON.parse(row.data) : row.data;
    const png = await generateOgImage(row.type, data);
    res.set({ 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=86400' });
    res.send(png);
  } catch (err) {
    console.error('og image error:', err);
    res.status(500).send('Image generation failed');
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
