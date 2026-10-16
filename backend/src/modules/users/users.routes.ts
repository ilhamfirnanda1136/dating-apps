import { Router, type Request, type Response } from 'express';
import { authenticate } from '../../common/middlewares/authenticate';
import { validateBody } from '../../common/middlewares/validate';
import * as usersService from './users.service';
import { addPhotoSchema, updateLocationSchema, updatePreferencesSchema, updateProfileSchema } from './users.schema';
import type { AddPhotoInput, UpdateLocationInput, UpdatePreferencesInput, UpdateProfileInput } from './users.schema';

export const meRouter = Router();

meRouter.use(authenticate);

meRouter.get('/', async (req: Request, res: Response) => {
  const user = await usersService.getMe(req.user!.id);
  res.json({ data: user });
});

meRouter.put('/profile', validateBody(updateProfileSchema), async (req: Request, res: Response) => {
  const user = await usersService.updateProfile(req.user!.id, req.body as UpdateProfileInput);
  res.json({ data: user });
});

meRouter.put('/location', validateBody(updateLocationSchema), async (req: Request, res: Response) => {
  const user = await usersService.updateLocation(req.user!.id, req.body as UpdateLocationInput);
  res.json({ data: user });
});

meRouter.get('/preferences', async (req: Request, res: Response) => {
  const preference = await usersService.getPreferences(req.user!.id);
  res.json({ data: preference });
});

meRouter.put('/preferences', validateBody(updatePreferencesSchema), async (req: Request, res: Response) => {
  const preference = await usersService.updatePreferences(req.user!.id, req.body as UpdatePreferencesInput);
  res.json({ data: preference });
});

meRouter.post('/photos', validateBody(addPhotoSchema), async (req: Request, res: Response) => {
  const user = await usersService.addPhoto(req.user!.id, req.body as AddPhotoInput);
  res.status(201).json({ data: user });
});

meRouter.delete('/photos/:id', async (req: Request, res: Response) => {
  const user = await usersService.removePhoto(req.user!.id, String(req.params.id));
  res.json({ data: user });
});
