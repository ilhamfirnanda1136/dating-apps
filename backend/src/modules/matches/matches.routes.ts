import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate';
import { validateBody } from '../../common/middlewares/validate';
import * as matchesService from './matches.service';

const messageSchema = z
  .object({
    content: z.string().trim().max(2000).optional().default(''),
    media_url: z.string().trim().optional().nullable(),
    reply_to_id: z.string().uuid().optional().nullable(),
  })
  .refine(
    (data) => (data.content && data.content.length > 0) || (data.media_url && data.media_url.length > 0),
    { message: 'Pesan atau foto harus diisi' },
  );

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
  const data = await matchesService.sendMessage(
    req.user!.id,
    String(req.params.id),
    body.content,
    body.media_url,
    body.reply_to_id,
  );
  res.status(201).json({ data });
});

matchesRouter.patch('/:id/messages/read', async (req: Request, res: Response) => {
  await matchesService.markRead(req.user!.id, String(req.params.id));
  res.status(204).send();
});
