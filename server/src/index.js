import 'dotenv/config';
import cors from 'cors';
import express from 'express';

import fortuneRoutes from './routes/fortune.js';
import dailyRoutes from './routes/daily.js';
import diaryRoutes from './routes/diary.js';
import compatibilityRoutes from './routes/compatibility.js';

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
app.use('/api/diary', diaryRoutes);
app.use('/api/compatibility', compatibilityRoutes);

app.listen(port, '0.0.0.0', () => {
  console.log(`Unmyeong Diary server listening on 0.0.0.0:${port}`);
});
