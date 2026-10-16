import { Router, type Request, type Response } from 'express';
import { AppError } from '../../common/errors';
import { authenticate } from '../../common/middlewares/authenticate';
import { Notification } from '../../models';

export const notificationsRouter = Router();
notificationsRouter.use(authenticate);

notificationsRouter.get('/', async (req: Request, res: Response) => {
  const rows = await Notification.findAll({
    where: { user_id: req.user!.id },
    order: [['created_at', 'DESC']],
    limit: 50,
  });
  res.json({ data: rows });
});

notificationsRouter.patch('/:id/read', async (req: Request, res: Response) => {
  const row = await Notification.findOne({ where: { id: req.params.id, user_id: req.user!.id } });
  if (!row) throw AppError.notFound('Notifikasi tidak ditemukan');
  row.is_read = true;
  await row.save();
  res.json({ data: row });
});
