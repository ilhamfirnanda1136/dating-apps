import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../errors';
import { verifyAccessToken } from '../../modules/auth/token.service';
import { User } from '../../models';

export async function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw AppError.unauthorized('Header Authorization Bearer wajib diisi');
  }

  const payload = verifyAccessToken(header.slice(7));

  // Status dicek ulang tiap request agar suspend dari admin langsung berlaku.
  const user = await User.findByPk(payload.sub, { attributes: ['id', 'role', 'status'] });
  if (!user || user.status === 'deleted') {
    throw AppError.unauthorized('Akun tidak ditemukan');
  }
  if (user.status === 'suspended') {
    throw AppError.forbidden('Akun sedang ditangguhkan');
  }

  req.user = { id: user.id, role: user.role };
  next();
}
