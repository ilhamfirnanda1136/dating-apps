import { createHash, randomBytes } from 'crypto';
import jwt from 'jsonwebtoken';
import { Op, Transaction } from 'sequelize';
import { env } from '../../config/env';
import { RefreshToken } from '../../models';
import type { UserRole } from '../../models/user.model';

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.JWT_ACCESS_SECRET) as AccessTokenPayload;
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export interface ClientInfo {
  userAgent?: string;
  ip?: string;
}

export async function issueRefreshToken(userId: string, client: ClientInfo, transaction?: Transaction) {
  const token = randomBytes(48).toString('base64url');
  const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);

  await RefreshToken.create(
    {
      user_id: userId,
      token_hash: hashToken(token),
      expires_at: expiresAt,
      user_agent: client.userAgent?.slice(0, 255) ?? null,
      ip_address: client.ip ?? null,
    },
    { transaction },
  );

  return { token, expiresAt };
}

export async function findActiveRefreshToken(token: string, transaction?: Transaction) {
  return RefreshToken.findOne({
    where: {
      token_hash: hashToken(token),
      revoked_at: null,
      expires_at: { [Op.gt]: new Date() },
    },
    transaction,
    lock: transaction ? transaction.LOCK.UPDATE : undefined,
  });
}
