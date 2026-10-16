import { Op } from 'sequelize';
import { AppError } from '../../common/errors';
import { Match, Notification, Profile, Swipe, User } from '../../models';
import { toPublicProfile } from '../common/public-profile';

const LIKE_ACTIONS = ['like', 'super_like'] as const;

export async function createSwipe(swiperId: string, targetId: string, action: 'like' | 'pass' | 'super_like') {
  if (swiperId === targetId) throw AppError.badRequest('Tidak bisa swipe diri sendiri');

  const target = await User.findByPk(targetId);
  if (!target || target.status !== 'active' || target.role !== 'user') {
    throw AppError.notFound('Pengguna tidak ditemukan');
  }

  try {
    await Swipe.create({ swiper_id: swiperId, target_id: targetId, action });
  } catch (error) {
    const name = error instanceof Error ? error.name : '';
    if (name === 'SequelizeUniqueConstraintError') {
      throw AppError.conflict('Kamu sudah menilai profil ini');
    }
    throw error;
  }

  let match = null;
  if (action !== 'pass') {
    const reverse = await Swipe.findOne({
      where: { swiper_id: targetId, target_id: swiperId, action: { [Op.in]: [...LIKE_ACTIONS] } },
    });
    if (reverse) {
      match = await ensureMatch(swiperId, targetId);
    }
  }

  return {
    action,
    target_id: targetId,
    match: match
      ? { id: match.id, status: match.status, matched_at: match.matched_at }
      : null,
  };
}

async function ensureMatch(userId1: string, userId2: string) {
  const [userA, userB] = Match.orderPair(userId1, userId2);
  const existing = await Match.findOne({ where: { user_a_id: userA, user_b_id: userB } });
  if (existing) {
    if (existing.status !== 'active') {
      existing.status = 'active';
      existing.matched_at = new Date();
      await existing.save();
    }
    return existing;
  }

  const created = await Match.create({ user_a_id: userA, user_b_id: userB, status: 'active' });
  const [profileA, profileB] = await Promise.all([
    Profile.findOne({ where: { user_id: userId1 } }),
    Profile.findOne({ where: { user_id: userId2 } }),
  ]);

  await Notification.bulkCreate([
    {
      user_id: userId1,
      type: 'match',
      title: `Kamu match dengan ${profileB?.full_name ?? 'seseorang'}`,
      body: 'Kalian saling menyukai. Sapa duluan, jangan canggung.',
      data: { match_id: created.id, user_id: userId2 },
    },
    {
      user_id: userId2,
      type: 'match',
      title: `Kamu match dengan ${profileA?.full_name ?? 'seseorang'}`,
      body: 'Kalian saling menyukai. Sapa duluan, jangan canggung.',
      data: { match_id: created.id, user_id: userId1 },
    },
  ]);

  return created;
}

export async function listLikes(viewerId: string) {
  const likes = await Swipe.findAll({
    where: { target_id: viewerId, action: { [Op.in]: [...LIKE_ACTIONS] } },
    order: [['created_at', 'DESC']],
    include: [
      {
        association: 'swiper',
        required: true,
        where: { status: 'active', role: 'user' },
        include: [{ association: 'profile' }, { association: 'photos', separate: true, order: [['sort_order', 'ASC']] }],
      },
    ],
  });

  const matched = await Match.findAll({
    where: {
      status: 'active',
      [Op.or]: [{ user_a_id: viewerId }, { user_b_id: viewerId }],
    },
  });
  const matchedIds = new Set(
    matched.map((row) => (row.user_a_id === viewerId ? row.user_b_id : row.user_a_id)),
  );

  return likes
    .map((swipe) => swipe.get('swiper') as User | undefined)
    .filter((user): user is User => Boolean(user) && !matchedIds.has(user!.id))
    .map((user) => toPublicProfile(user, { likedYou: true }));
}
