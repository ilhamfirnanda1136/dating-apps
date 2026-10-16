'use strict';

const { randomUUID } = require('crypto');
const bcrypt = require('bcryptjs');

const email = 'budi@mail.com';
const password = 'password123';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    const [rows] = await queryInterface.sequelize.query('SELECT id FROM users WHERE email = ? LIMIT 1', {
      replacements: [email],
    });
    if (rows.length) return;

    const now = new Date();
    const userId = randomUUID();

    await queryInterface.bulkInsert('users', [
      {
        id: userId,
        email,
        password_hash: await bcrypt.hash(password, 10),
        role: 'user',
        status: 'active',
        created_at: now,
        updated_at: now,
      },
    ]);

    await queryInterface.bulkInsert('profiles', [
      {
        id: randomUUID(),
        user_id: userId,
        full_name: 'Budi',
        birth_date: '1998-05-10',
        gender: 'male',
        bio: 'Suka kopi, naik gunung, dan diskusi film sampai lupa waktu.',
        job: 'Product Designer',
        city: 'Jakarta Selatan',
        is_verified: true,
        created_at: now,
        updated_at: now,
      },
    ]);

    await queryInterface.bulkInsert('preferences', [
      {
        id: randomUUID(),
        user_id: userId,
        interested_in: 'female',
        min_age: 18,
        max_age: 99,
        max_distance_km: 50,
        created_at: now,
        updated_at: now,
      },
    ]);
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('users', { email });
  },
};
