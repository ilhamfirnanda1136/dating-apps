'use strict';

const { randomUUID } = require('crypto');
const bcrypt = require('bcryptjs');

const COUNT = 50;
const PASSWORD = 'password123';
const EMAILS = Array.from({ length: COUNT }, (_, i) => `seed${String(i + 1).padStart(2, '0')}@mail.com`);

const FEMALE_NAMES = [
  'Ayu Lestari', 'Maya Putri', 'Sinta Dewi', 'Nadia Rahma', 'Dinda Ayu',
  'Farah Nabila', 'Gita Sari', 'Hana Kirana', 'Intan Permata', 'Jihan Aulia',
  'Laila Zahra', 'Mira Anggraini', 'Nabila Kusuma', 'Olivia Tan', 'Putri Amalia',
  'Rara Melati', 'Salsa Anindya', 'Tania Wijaya', 'Vina Oktavia', 'Wulan Sari',
  'Yuni Pratiwi', 'Zahra Malik', 'Amira Fadila', 'Bella Cahyani', 'Citra Anjani',
  'Dian Safitri', 'Elena Prameswari', 'Fira Nuraini', 'Hesti Wulandari', 'Indah Pramesti',
];

const MALE_NAMES = [
  'Andi Pratama', 'Bima Sakti', 'Cahyo Nugroho', 'Dimas Arya', 'Eko Prasetyo',
  'Fajar Ramadhan', 'Gilang Wijaya', 'Hadi Kusuma', 'Irfan Maulana', 'Kurniawan Adi',
  'Luthfi Hakim', 'Mario Santoso', 'Nanda Putra', 'Omar Syahputra', 'Rizky Fadillah',
  'Satria Wibowo', 'Wahyu Hidayat', 'Yoga Pranata', 'Zaki Firmansyah', 'Bayu Anggara',
];

const JOBS = [
  'Product Designer', 'Software Engineer', 'Guru', 'Dokter', 'Digital Marketer',
  'Barista', 'Arsitek', 'Content Creator', 'Perawat', 'Akuntan',
  'Fotografer', 'Chef', 'HR Specialist', 'Data Analyst', 'Pengacara',
  'Copywriter', 'UI Researcher', 'Pharmacist', 'Event Organizer', 'Illustrator',
];

const BIOS = [
  'Suka kopi specialty dan jalan sore di kota. Ajak ngobrol tentang film atau musik.',
  'Weekend-ku biasanya hiking ringan atau cari tempat makan baru.',
  'Introvert yang ramah. Lebih suka obrolan dalam daripada small talk.',
  'Tinggal di Jakarta, kerja remote, dan masih percaya match bisa jadi cerita bagus.',
  'Doyan kuliner, museum, dan playlist yang diputar pelan-pelan.',
  'Olahraga tiga kali seminggu, sisanya nonton series sampai ketiduran.',
  'Cari orang yang bisa ketawa bareng dan tidak ribet.',
  'Suka fotografi jalanan. Kalau ada waktu, keliling kota naik KRL.',
  'Pecinta buku dan cafe yang sepi. Ceritakan buku terakhir yang kamu baca.',
  'Baru pindah ke Jabodetabek. Siap eksplor tempat baru kalau bareng orang yang pas.',
];

const CITIES = [
  { city: 'Jakarta Selatan', lat: -6.2615, lng: 106.8106 },
  { city: 'Jakarta Pusat', lat: -6.1865, lng: 106.8344 },
  { city: 'Jakarta Barat', lat: -6.1683, lng: 106.7588 },
  { city: 'Jakarta Utara', lat: -6.1384, lng: 106.8636 },
  { city: 'Jakarta Timur', lat: -6.2250, lng: 106.9004 },
  { city: 'Depok', lat: -6.4025, lng: 106.7942 },
  { city: 'Tangerang', lat: -6.1783, lng: 106.6319 },
  { city: 'Bekasi', lat: -6.2383, lng: 106.9756 },
  { city: 'Bogor', lat: -6.5971, lng: 106.8060 },
  { city: 'Bandung', lat: -6.9175, lng: 107.6191 },
];

function pick(list, index, salt = 0) {
  return list[(index * 11 + salt) % list.length];
}

function jitter(value, index, scale) {
  const delta = (((index * 17) % 21) - 10) / 1000;
  return Number((value + delta * scale).toFixed(6));
}

function birthDate(index) {
  const age = 21 + (index % 16);
  const year = new Date().getFullYear() - age;
  const month = String((index % 12) + 1).padStart(2, '0');
  const day = String((index % 27) + 1).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function portraitUrl(gender, index, shot) {
  const folder = gender === 'female' ? 'women' : 'men';
  const n = (index * 3 + shot) % 99;
  return `https://randomuser.me/api/portraits/${folder}/${n}.jpg`;
}

function person(index) {
  const female = index < 30;
  const gender = female ? 'female' : 'male';
  const nameIndex = female ? index : index - 30;
  const names = female ? FEMALE_NAMES : MALE_NAMES;
  const place = pick(CITIES, index, 3);
  const interestedIn = female
    ? index % 7 === 0
      ? 'all'
      : 'male'
    : index % 5 === 0
      ? 'all'
      : 'female';

  return {
    email: EMAILS[index],
    gender,
    fullName: names[nameIndex % names.length],
    birthDate: birthDate(index),
    job: pick(JOBS, index, 2),
    bio: pick(BIOS, index, 5),
    city: place.city,
    latitude: jitter(place.lat, index, 8),
    longitude: jitter(place.lng, index, 8),
    isVerified: index % 4 === 0,
    interestedIn,
    minAge: 21,
    maxAge: 38,
    maxDistanceKm: 25 + (index % 6) * 10,
    photoCount: 2 + (index % 2),
  };
}

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    const [existing] = await queryInterface.sequelize.query(
      `SELECT email FROM users WHERE email IN (${EMAILS.map(() => '?').join(',')})`,
      { replacements: EMAILS },
    );
    const taken = new Set(existing.map((row) => row.email));
    const pending = EMAILS.map((_, index) => index).filter((index) => !taken.has(EMAILS[index]));
    if (!pending.length) return;

    const now = new Date();
    const passwordHash = await bcrypt.hash(PASSWORD, 10);
    const users = [];
    const profiles = [];
    const preferences = [];
    const photos = [];

    for (const index of pending) {
      const data = person(index);
      const userId = randomUUID();
      users.push({
        id: userId,
        email: data.email,
        password_hash: passwordHash,
        role: 'user',
        status: 'active',
        created_at: now,
        updated_at: now,
      });
      profiles.push({
        id: randomUUID(),
        user_id: userId,
        full_name: data.fullName,
        birth_date: data.birthDate,
        gender: data.gender,
        bio: data.bio,
        job: data.job,
        city: data.city,
        latitude: data.latitude,
        longitude: data.longitude,
        is_verified: data.isVerified,
        created_at: now,
        updated_at: now,
      });
      preferences.push({
        id: randomUUID(),
        user_id: userId,
        interested_in: data.interestedIn,
        min_age: data.minAge,
        max_age: data.maxAge,
        max_distance_km: data.maxDistanceKm,
        created_at: now,
        updated_at: now,
      });
      for (let shot = 0; shot < data.photoCount; shot += 1) {
        photos.push({
          id: randomUUID(),
          user_id: userId,
          url: portraitUrl(data.gender, index, shot),
          sort_order: shot,
          is_primary: shot === 0,
          created_at: now,
          updated_at: now,
        });
      }
    }

    await queryInterface.bulkInsert('users', users);
    await queryInterface.bulkInsert('profiles', profiles);
    await queryInterface.bulkInsert('preferences', preferences);
    await queryInterface.bulkInsert('photos', photos);
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('users', { email: EMAILS });
  },
};
