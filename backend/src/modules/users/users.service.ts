import type { Includeable } from 'sequelize';
import { AppError } from '../../common/errors';
import { calculateAge } from '../../common/utils/age';
import { Photo, Preference, Profile, User } from '../../models';
import type { AddPhotoInput, UpdateLocationInput, UpdatePreferencesInput, UpdateProfileInput } from './users.schema';

const ME_INCLUDE: Includeable[] = [
  { association: 'profile' },
  { association: 'preference' },
  { association: 'photos', separate: true, order: [['sort_order', 'ASC']] },
];

export async function getMe(userId: string) {
  const user = await User.findByPk(userId, { include: ME_INCLUDE });
  if (!user) throw AppError.notFound('Akun tidak ditemukan');
  return user;
}

export async function updateProfile(userId: string, input: UpdateProfileInput) {
  if (input.birth_date && calculateAge(input.birth_date) < 18) {
    throw AppError.badRequest('Usia minimal 18 tahun');
  }

  const profile = await Profile.findOne({ where: { user_id: userId } });
  if (!profile) throw AppError.notFound('Profil tidak ditemukan');

  await profile.update({
    ...(input.full_name !== undefined ? { full_name: input.full_name } : {}),
    ...(input.bio !== undefined ? { bio: input.bio } : {}),
    ...(input.city !== undefined ? { city: input.city } : {}),
    ...(input.job !== undefined ? { job: input.job } : {}),
    ...(input.gender !== undefined ? { gender: input.gender } : {}),
    ...(input.birth_date !== undefined ? { birth_date: input.birth_date } : {}),
  });

  return getMe(userId);
}

export async function updateLocation(userId: string, input: UpdateLocationInput) {
  const profile = await Profile.findOne({ where: { user_id: userId } });
  if (!profile) throw AppError.notFound('Profil tidak ditemukan');

  await profile.update({
    latitude: input.latitude,
    longitude: input.longitude,
    ...(input.city !== undefined ? { city: input.city } : {}),
  });

  return getMe(userId);
}

export async function getPreferences(userId: string) {
  const preference = await Preference.findOne({ where: { user_id: userId } });
  if (!preference) throw AppError.notFound('Preferensi tidak ditemukan');
  return preference;
}

export async function updatePreferences(userId: string, input: UpdatePreferencesInput) {
  const preference = await Preference.findOne({ where: { user_id: userId } });
  if (!preference) throw AppError.notFound('Preferensi tidak ditemukan');

  const minAge = input.min_age ?? preference.min_age;
  const maxAge = input.max_age ?? preference.max_age;
  if (minAge > maxAge) throw AppError.badRequest('Usia minimum tidak boleh lebih besar dari usia maksimum');

  await preference.update(input);
  return preference;
}

export async function addPhoto(userId: string, input: AddPhotoInput) {
  const count = await Photo.count({ where: { user_id: userId } });
  if (count >= 6) throw AppError.badRequest('Maksimal 6 foto');

  const isPrimary = input.is_primary === true || count === 0;
  if (isPrimary) {
    await Photo.update({ is_primary: false }, { where: { user_id: userId } });
  }

  await Photo.create({
    user_id: userId,
    url: input.url,
    sort_order: count,
    is_primary: isPrimary,
  });

  return getMe(userId);
}

export async function removePhoto(userId: string, photoId: string) {
  const photo = await Photo.findOne({ where: { id: photoId, user_id: userId } });
  if (!photo) throw AppError.notFound('Foto tidak ditemukan');
  await photo.destroy();
  return getMe(userId);
}
