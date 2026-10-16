import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { UniqueConstraintError, ValidationError as SequelizeValidationError } from 'sequelize';
import jwt from 'jsonwebtoken';
import { AppError } from '../errors';
import { env } from '../../config/env';

export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(AppError.notFound(`Route ${req.method} ${req.originalUrl} tidak ditemukan`));
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }

  if (err instanceof ZodError) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Input tidak valid',
        details: err.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message })),
      },
    });
  }

  if (err instanceof UniqueConstraintError) {
    return res.status(409).json({
      error: {
        code: 'CONFLICT',
        message: 'Data sudah ada',
        details: err.errors.map((e) => ({ field: e.path, message: e.message })),
      },
    });
  }

  if (err instanceof SequelizeValidationError) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Input tidak valid',
        details: err.errors.map((e) => ({ field: e.path, message: e.message })),
      },
    });
  }

  if (err instanceof jwt.TokenExpiredError) {
    return res.status(401).json({ error: { code: 'TOKEN_EXPIRED', message: 'Access token kedaluwarsa' } });
  }

  if (err instanceof jwt.JsonWebTokenError) {
    return res.status(401).json({ error: { code: 'INVALID_TOKEN', message: 'Access token tidak valid' } });
  }

  if (err instanceof SyntaxError && 'body' in err) {
    return res.status(400).json({ error: { code: 'BAD_REQUEST', message: 'Body JSON tidak valid' } });
  }

  console.error(err);
  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Terjadi kesalahan pada server',
      details: env.NODE_ENV === 'development' && err instanceof Error ? err.message : undefined,
    },
  });
}
