'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('profiles', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        unique: true,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      full_name: { type: Sequelize.STRING(100), allowNull: false },
      birth_date: { type: Sequelize.DATEONLY, allowNull: false },
      gender: { type: Sequelize.STRING(20), allowNull: false },
      bio: { type: Sequelize.TEXT, allowNull: true },
      city: { type: Sequelize.STRING(100), allowNull: true },
      latitude: { type: Sequelize.DOUBLE, allowNull: true },
      longitude: { type: Sequelize.DOUBLE, allowNull: true },
      is_verified: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('profiles', ['latitude', 'longitude'], { name: 'idx_profiles_location' });
    await queryInterface.addIndex('profiles', ['gender', 'birth_date'], { name: 'idx_profiles_gender_birth' });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('profiles');
  },
};
