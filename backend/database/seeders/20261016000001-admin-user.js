'use strict';

require('dotenv').config({ quiet: true });
const { randomUUID } = require('crypto');
const bcrypt = require('bcryptjs');

const email = process.env.SEED_ADMIN_EMAIL || 'admin@datingapp.local';
const password = process.env.SEED_ADMIN_PASSWORD || 'Admin12345';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    const now = new Date();
    const userId = randomUUID();

    await queryInterface.bulkInsert('users', [
      {
        id: userId,
        email,
        password_hash: await bcrypt.hash(password, 10),
        role: 'admin',
        status: 'active',
        created_at: now,
        updated_at: now,
      },
    ]);

    await queryInterface.bulkInsert('profiles', [
      {
        id: randomUUID(),
        user_id: userId,
        full_name: 'Administrator',
        birth_date: '1990-01-01',
        gender: 'male',
        is_verified: true,
        created_at: now,
        updated_at: now,
      },
    ]);
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('users', { email });
  },
};
