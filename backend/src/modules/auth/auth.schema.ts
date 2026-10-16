import { z } from 'zod';

export const GENDERS = ['male', 'female'] as const;
export const INTERESTED_IN = ['male', 'female', 'all'] as const;

export const registerSchema = z.object({
  email: z.email().max(255).transform((v) => v.toLowerCase()),
  password: z.string().min(8).max(72),
  phone: z
    .string()
    .regex(/^\+?[0-9]{8,15}$/, 'Format nomor telepon tidak valid')
    .optional(),
  full_name: z.string().trim().min(1).max(100),
  birth_date: z.iso.date(),
  gender: z.enum(GENDERS),
  interested_in: z.enum(INTERESTED_IN),
});

export const loginSchema = z.object({
  email: z.email().transform((v) => v.toLowerCase()),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
