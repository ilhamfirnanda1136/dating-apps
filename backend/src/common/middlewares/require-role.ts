import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../errors';
import type { UserRole } from '../../models/user.model';

export function requireRole(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) throw AppError.unauthorized();
    if (!roles.includes(req.user.role)) throw AppError.forbidden();
    next();
  };
}
