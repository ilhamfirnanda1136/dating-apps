import { z } from 'zod';

export const updateProfileSchema = z
  .object({
    full_name: z.string().trim().min(1).max(100).optional(),
    bio: z.string().max(2000).optional().nullable(),
    city: z.string().trim().max(100).optional().nullable(),
    job: z.string().trim().max(100).optional().nullable(),
    gender: z.enum(['male', 'female']).optional(),
    birth_date: z.iso.date().optional(),
  })
  .refine((value) => Object.values(value).some((item) => item !== undefined), {
    message: 'Tidak ada perubahan',
  });

export const updateLocationSchema = z.object({
  latitude: z.number().gte(-90).lte(90),
  longitude: z.number().gte(-180).lte(180),
  city: z.string().trim().max(100).optional(),
});

export const updatePreferencesSchema = z
  .object({
    interested_in: z.enum(['male', 'female', 'all']).optional(),
    min_age: z.number().int().min(18).max(99).optional(),
    max_age: z.number().int().min(18).max(99).optional(),
    max_distance_km: z.number().int().min(1).max(500).optional(),
  })
  .refine((value) => Object.values(value).some((item) => item !== undefined), {
    message: 'Tidak ada perubahan',
  });

export const addPhotoSchema = z.object({
  url: z.url(),
  is_primary: z.boolean().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type UpdateLocationInput = z.infer<typeof updateLocationSchema>;
export type UpdatePreferencesInput = z.infer<typeof updatePreferencesSchema>;
export type AddPhotoInput = z.infer<typeof addPhotoSchema>;
