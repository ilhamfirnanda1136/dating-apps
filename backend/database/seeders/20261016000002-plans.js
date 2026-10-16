'use strict';

const { randomUUID } = require('crypto');

const plans = [
  {
    name: 'Premium 1 Bulan',
    price: 49000,
    duration_days: 30,
    features: { unlimited_likes: true, super_likes_per_day: 5, see_who_likes_you: true },
  },
  {
    name: 'Premium 3 Bulan',
    price: 129000,
    duration_days: 90,
    features: { unlimited_likes: true, super_likes_per_day: 5, see_who_likes_you: true },
  },
  {
    name: 'Premium 12 Bulan',
    price: 399000,
    duration_days: 365,
    features: { unlimited_likes: true, super_likes_per_day: 10, see_who_likes_you: true, boost_per_month: 1 },
  },
];

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    const now = new Date();
    await queryInterface.bulkInsert(
      'plans',
      plans.map((plan) => ({
        id: randomUUID(),
        ...plan,
        features: JSON.stringify(plan.features),
        is_active: true,
        created_at: now,
        updated_at: now,
      })),
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('plans', {
      name: { [Sequelize.Op.in]: plans.map((plan) => plan.name) },
    });
  },
};
