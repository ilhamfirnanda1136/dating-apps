export function calculateAge(birthDate: string | Date, now: Date = new Date()): number {
  const birth = typeof birthDate === 'string' ? new Date(`${birthDate}T00:00:00Z`) : birthDate;
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  const monthDiff = now.getUTCMonth() - birth.getUTCMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getUTCDate() < birth.getUTCDate())) {
    age--;
  }
  return age;
}
