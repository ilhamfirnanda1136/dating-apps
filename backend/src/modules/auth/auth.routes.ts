import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authenticate } from '../../common/middlewares/authenticate';
import { validateBody } from '../../common/middlewares/validate';
import * as controller from './auth.controller';
import { loginSchema, refreshSchema, registerSchema } from './auth.schema';

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Terlalu banyak percobaan, coba lagi nanti' } },
});

export const authRouter = Router();

authRouter.post('/register', authLimiter, validateBody(registerSchema), controller.register);
authRouter.post('/login', authLimiter, validateBody(loginSchema), controller.login);
authRouter.post('/refresh', validateBody(refreshSchema), controller.refresh);
authRouter.post('/logout', authenticate, validateBody(refreshSchema), controller.logout);
