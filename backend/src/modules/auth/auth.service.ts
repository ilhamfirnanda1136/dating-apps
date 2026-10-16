import bcrypt from 'bcryptjs';
import { sequelize, User, Profile, Preference } from '../../models';
import { AppError } from '../../common/errors';
import { calculateAge } from '../../common/utils/age';
import { getMe } from '../users/users.service';
import type { LoginInput, RegisterInput } from './auth.schema';
import {
  ClientInfo,
  findActiveRefreshToken,
  issueRefreshToken,
  signAccessToken,
} from './token.service';

const MIN_AGE = 18;
const BCRYPT_ROUNDS = 10;

async function buildTokens(user: User, client: ClientInfo) {
  const accessToken = signAccessToken({ sub: user.id, role: user.role });
  const refresh = await issueRefreshToken(user.id, client);
  return {
    access_token: accessToken,
    refresh_token: refresh.token,
    refresh_token_expires_at: refresh.expiresAt,
    token_type: 'Bearer',
  };
}

export async function register(input: RegisterInput, client: ClientInfo) {
  if (calculateAge(input.birth_date) < MIN_AGE) {
    throw AppError.badRequest(`Usia minimal ${MIN_AGE} tahun`);
  }

  const existing = await User.findOne({ where: { email: input.email }, attributes: ['id'] });
  if (existing) throw AppError.conflict('Email sudah terdaftar');

  if (input.phone) {
    const phoneUsed = await User.findOne({ where: { phone: input.phone }, attributes: ['id'] });
    if (phoneUsed) throw AppError.conflict('Nomor telepon sudah terdaftar');
  }

  const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);

  const userId = await sequelize.transaction(async (transaction) => {
    const created = await User.create(
      { email: input.email, phone: input.phone ?? null, password_hash: passwordHash, last_login_at: new Date() },
      { transaction },
    );
    await Profile.create(
      {
        user_id: created.id,
        full_name: input.full_name,
        birth_date: input.birth_date,
        gender: input.gender,
      },
      { transaction },
    );
    await Preference.create({ user_id: created.id, interested_in: input.interested_in }, { transaction });
    return created.id;
  });

  const account = await getMe(userId);
  return { user: account, tokens: await buildTokens(account, client) };
}

export async function login(input: LoginInput, client: ClientInfo) {
  const user = await User.findOne({ where: { email: input.email } });
  const passwordOk = user ? await bcrypt.compare(input.password, user.password_hash) : false;

  if (!user || !passwordOk || user.status === 'deleted') {
    throw AppError.unauthorized('Email atau password salah');
  }
  if (user.status === 'suspended') {
    throw AppError.forbidden('Akun sedang ditangguhkan');
  }

  user.last_login_at = new Date();
  await user.save();

  return { user: await getMe(user.id), tokens: await buildTokens(user, client) };
}

export async function refresh(refreshToken: string, client: ClientInfo) {
  return sequelize.transaction(async (transaction) => {
    const stored = await findActiveRefreshToken(refreshToken, transaction);
    if (!stored) throw AppError.unauthorized('Refresh token tidak valid atau kedaluwarsa');

    const user = await User.findByPk(stored.user_id, { transaction });
    if (!user || user.status !== 'active') {
      throw AppError.unauthorized('Akun tidak aktif');
    }

    stored.revoked_at = new Date();
    await stored.save({ transaction });

    const next = await issueRefreshToken(user.id, client, transaction);
    return {
      access_token: signAccessToken({ sub: user.id, role: user.role }),
      refresh_token: next.token,
      refresh_token_expires_at: next.expiresAt,
      token_type: 'Bearer',
    };
  });
}

export async function logout(userId: string, refreshToken: string) {
  const stored = await findActiveRefreshToken(refreshToken);
  if (stored && stored.user_id === userId) {
    stored.revoked_at = new Date();
    await stored.save();
  }
}
