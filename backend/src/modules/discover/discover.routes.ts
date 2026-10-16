import { Router, type Request, type Response } from 'express';
import { authenticate } from '../../common/middlewares/authenticate';
import * as discoverService from './discover.service';

export const discoverRouter = Router();

discoverRouter.use(authenticate);

discoverRouter.get('/', async (req: Request, res: Response) => {
  const limit = Number(req.query.limit ?? 20);
  const data = await discoverService.listDiscover(req.user!.id, Number.isFinite(limit) ? limit : 20);
  res.json({ data });
});
