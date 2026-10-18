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

    const now = new Date();
    const endAt = new Date();
    endAt.setFullYear(endAt.getFullYear() + 1);

    const [plans] = await queryInterface.sequelize.query(
      "SELECT id FROM plans WHERE name LIKE '%12 Bulan%' LIMIT 1"
    );
    const planId = plans.length ? plans[0].id : null;

    let targetUserId;
    if (rows.length) {
      targetUserId = rows[0].id;
    } else {
      targetUserId = randomUUID();
      await queryInterface.bulkInsert('users', [
        {
          id: targetUserId,
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
          user_id: targetUserId,
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
          user_id: targetUserId,
          interested_in: 'female',
          min_age: 18,
          max_age: 99,
          max_distance_km: 50,
          created_at: now,
          updated_at: now,
        },
      ]);
    }

    if (planId) {
      const [existingSubs] = await queryInterface.sequelize.query(
        "SELECT id FROM subscriptions WHERE user_id = ? AND status = 'active' LIMIT 1",
        { replacements: [targetUserId] }
      );
      if (!existingSubs.length) {
        await queryInterface.bulkInsert('subscriptions', [
          {
            id: randomUUID(),
            user_id: targetUserId,
            plan_id: planId,
            status: 'active',
            start_at: now,
            end_at: endAt,
            created_at: now,
            updated_at: now,
          },
        ]);
      }
    }
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('users', { email });
  },
};
