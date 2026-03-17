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

app.use(express.static(path.join(__dirname, '..', 'public')));

await initDb();

app.listen(port, '0.0.0.0', () => {
  console.log(`Unmyeong Diary server listening on 0.0.0.0:${port}`);
});
