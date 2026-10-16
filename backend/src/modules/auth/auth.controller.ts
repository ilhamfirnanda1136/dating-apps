import type { Request, Response } from 'express';
import * as authService from './auth.service';
import type { ClientInfo } from './token.service';
import type { LoginInput, RefreshInput, RegisterInput } from './auth.schema';

type BodyRequest<T> = Request<Record<string, string>, unknown, T>;

function clientInfo(req: Request): ClientInfo {
  return { userAgent: req.get('user-agent'), ip: req.ip };
}

export async function register(req: BodyRequest<RegisterInput>, res: Response) {
  const result = await authService.register(req.body, clientInfo(req));
  res.status(201).json({ data: result });
}

export async function login(req: BodyRequest<LoginInput>, res: Response) {
  const result = await authService.login(req.body, clientInfo(req));
  res.json({ data: result });
}

export async function refresh(req: BodyRequest<RefreshInput>, res: Response) {
  const tokens = await authService.refresh(req.body.refresh_token, clientInfo(req));
  res.json({ data: tokens });
}

export async function logout(req: BodyRequest<RefreshInput>, res: Response) {
  await authService.logout(req.user!.id, req.body.refresh_token);
  res.status(204).send();
}
