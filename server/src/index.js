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

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json());

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

app.use(express.static(path.join(__dirname, '..', 'public')));

await initDb();

app.listen(port, '0.0.0.0', () => {
  console.log(`Unmyeong Diary server listening on 0.0.0.0:${port}`);
});
