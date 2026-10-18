import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { env } from './config/env';
import { sequelize } from './models';
import { apiRouter } from './routes';
import { errorHandler, notFoundHandler } from './common/middlewares/error-handler';

export const app = express();

app.set('trust proxy', 1);
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({ origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',') }));
app.use(express.json({ limit: '20mb' }));

// Static serving untuk gambar yang diunggah
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', async (_req, res) => {
  try {
    await sequelize.authenticate();
    res.json({ status: 'ok', database: 'up' });
  } catch {
    res.status(503).json({ status: 'degraded', database: 'down' });
  }
});

app.use('/api/v1', apiRouter);

app.use(notFoundHandler);
app.use(errorHandler);
