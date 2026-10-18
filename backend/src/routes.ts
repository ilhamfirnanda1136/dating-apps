import { Router } from 'express';
import { authRouter } from './modules/auth/auth.routes';
import { meRouter } from './modules/users/users.routes';
import { adminRouter } from './modules/admin/admin.routes';
import { discoverRouter } from './modules/discover/discover.routes';
import { likesRouter, swipesRouter } from './modules/swipes/swipes.routes';
import { matchesRouter } from './modules/matches/matches.routes';
import { notificationsRouter } from './modules/notifications/notifications.routes';
import { uploadRouter } from './modules/upload/upload.routes';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/me', meRouter);
apiRouter.use('/discover', discoverRouter);
apiRouter.use('/swipes', swipesRouter);
apiRouter.use('/likes', likesRouter);
apiRouter.use('/matches', matchesRouter);
apiRouter.use('/notifications', notificationsRouter);
apiRouter.use('/admin', adminRouter);
apiRouter.use('/upload', uploadRouter);
