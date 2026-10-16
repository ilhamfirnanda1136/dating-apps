import { Op } from 'sequelize';
import { calculateAge } from '../../common/utils/age';
import { Block, Preference, Profile, Swipe, User } from '../../models';
import { haversineKm, toPublicProfile } from '../common/public-profile';

const LIKE_ACTIONS = ['like', 'super_like'] as const;

export async function listDiscover(viewerId: string, limit = 20) {
  const [preference, viewerProfile, swiped, blocks] = await Promise.all([
    Preference.findOne({ where: { user_id: viewerId } }),
    Profile.findOne({ where: { user_id: viewerId } }),
    Swipe.findAll({ where: { swiper_id: viewerId }, attributes: ['target_id'] }),
    Block.findAll({
      where: { [Op.or]: [{ blocker_id: viewerId }, { blocked_id: viewerId }] },
      attributes: ['blocker_id', 'blocked_id'],
    }),
  ]);

  const excluded = new Set<string>([viewerId, ...swiped.map((row) => row.target_id)]);
  for (const block of blocks) {
    excluded.add(block.blocker_id === viewerId ? block.blocked_id : block.blocker_id);
  }

  const profileWhere: Record<string, unknown> = {};
  if (preference && preference.interested_in !== 'all') {
    profileWhere.gender = preference.interested_in;
  }

  const candidates = await User.findAll({
    where: {
      id: { [Op.notIn]: [...excluded] },
      status: 'active',
      role: 'user',
    },
    include: [
      {
        association: 'profile',
        required: true,
        where: Object.keys(profileWhere).length ? profileWhere : undefined,
      },
      { association: 'preference' },
      { association: 'photos', separate: true, order: [['sort_order', 'ASC']] },
    ],
    limit: Math.min(Math.max(limit, 1), 50) * 3,
  });

  const minAge = preference?.min_age ?? 18;
  const maxAge = preference?.max_age ?? 99;
  const maxDistance = preference?.max_distance_km ?? 50;
  const viewerGender = viewerProfile?.gender;
  const viewerLat = viewerProfile?.latitude ?? null;
  const viewerLng = viewerProfile?.longitude ?? null;

  const filtered = candidates.filter((user) => {
    const profile = user.get('profile') as Profile;
    const theirPref = user.get('preference') as Preference | undefined;
    const age = profile.birth_date ? calculateAge(profile.birth_date) : 18;
    if (age < minAge || age > maxAge) return false;
    if (theirPref && viewerGender && theirPref.interested_in !== 'all' && theirPref.interested_in !== viewerGender) {
      return false;
    }
    if (viewerLat != null && viewerLng != null && profile.latitude != null && profile.longitude != null) {
      const distance = haversineKm(viewerLat, viewerLng, profile.latitude, profile.longitude);
      if (distance > maxDistance) return false;
    }
    return true;
  });

  const page = filtered.slice(0, Math.min(Math.max(limit, 1), 50));
  const reverseLikes = page.length
    ? await Swipe.findAll({
        where: {
          target_id: viewerId,
          swiper_id: { [Op.in]: page.map((user) => user.id) },
          action: { [Op.in]: [...LIKE_ACTIONS] },
        },
        attributes: ['swiper_id'],
      })
    : [];
  const likedYouIds = new Set(reverseLikes.map((row) => row.swiper_id));

  return page.map((user) =>
    toPublicProfile(user, {
      viewerLat,
      viewerLng,
      likedYou: likedYouIds.has(user.id),
    }),
  );
}
