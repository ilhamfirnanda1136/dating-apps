import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate';
import { validateBody } from '../../common/middlewares/validate';
import * as swipesService from './swipes.service';

const swipeSchema = z.object({
  target_id: z.uuid(),
  action: z.enum(['like', 'pass', 'super_like']),
});

export const swipesRouter = Router();
swipesRouter.use(authenticate);

swipesRouter.post('/', validateBody(swipeSchema), async (req: Request, res: Response) => {
  const body = req.body as z.infer<typeof swipeSchema>;
  const data = await swipesService.createSwipe(req.user!.id, body.target_id, body.action);
  res.status(201).json({ data });
});

export const likesRouter = Router();
likesRouter.use(authenticate);

likesRouter.get('/', async (req: Request, res: Response) => {
  const data = await swipesService.listLikes(req.user!.id);
  res.json({ data });
});
