import { calculateAge } from '../../common/utils/age';
import type { Photo } from '../../models/photo.model';
import type { Profile } from '../../models/profile.model';
import type { User } from '../../models/user.model';

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number) {
  const toRad = (n: number) => (n * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function toPublicProfile(
  user: User,
  options: {
    viewerLat?: number | null;
    viewerLng?: number | null;
    likedYou?: boolean;
  } = {},
) {
  const profile = user.get('profile') as Profile | undefined;
  const photos = (user.get('photos') as Photo[] | undefined) ?? [];
  const lat = profile?.latitude ?? null;
  const lng = profile?.longitude ?? null;
  let distanceKm = 0;
  if (
    options.viewerLat != null &&
    options.viewerLng != null &&
    lat != null &&
    lng != null
  ) {
    distanceKm = Math.round(haversineKm(options.viewerLat, options.viewerLng, lat, lng));
  }

  return {
    id: user.id,
    name: profile?.full_name ?? 'Pengguna',
    age: profile?.birth_date ? calculateAge(profile.birth_date) : 18,
    city: profile?.city ?? '',
    job: profile?.job ?? null,
    bio: profile?.bio ?? '',
    is_verified: profile?.is_verified ?? false,
    photos: photos
      .sort((a, b) => a.sort_order - b.sort_order)
      .map((photo) => ({ id: photo.id, url: photo.url, is_primary: photo.is_primary })),
    distance_km: distanceKm,
    liked_you: options.likedYou ?? false,
  };
}

export { haversineKm };
