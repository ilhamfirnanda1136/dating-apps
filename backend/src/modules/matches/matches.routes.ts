import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate';
import { validateBody } from '../../common/middlewares/validate';
import * as matchesService from './matches.service';

const messageSchema = z.object({
  content: z.string().trim().min(1).max(2000),
});

export const matchesRouter = Router();
matchesRouter.use(authenticate);

matchesRouter.get('/', async (req: Request, res: Response) => {
  const data = await matchesService.listMatches(req.user!.id);
  res.json({ data });
});

matchesRouter.delete('/:id', async (req: Request, res: Response) => {
  await matchesService.unmatch(req.user!.id, String(req.params.id));
  res.status(204).send();
});

matchesRouter.get('/:id/messages', async (req: Request, res: Response) => {
  const before = typeof req.query.before === 'string' ? req.query.before : undefined;
  const limit = Number(req.query.limit ?? 30);
  const data = await matchesService.listMessages(
    req.user!.id,
    String(req.params.id),
    before,
    Number.isFinite(limit) ? limit : 30,
  );
  res.json({ data });
});

matchesRouter.post('/:id/messages', validateBody(messageSchema), async (req: Request, res: Response) => {
  const body = req.body as z.infer<typeof messageSchema>;
  const data = await matchesService.sendMessage(req.user!.id, String(req.params.id), body.content);
  res.status(201).json({ data });
});

matchesRouter.patch('/:id/messages/read', async (req: Request, res: Response) => {
  await matchesService.markRead(req.user!.id, String(req.params.id));
  res.status(204).send();
});
