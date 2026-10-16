'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('preferences', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        unique: true,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      interested_in: { type: Sequelize.STRING(20), allowNull: false },
      min_age: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 18 },
      max_age: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 99 },
      max_distance_km: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 50 },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.sequelize.query(
      'ALTER TABLE preferences ADD CONSTRAINT chk_preferences_age CHECK (min_age >= 18 AND max_age >= min_age)',
    );
  },

  async down(queryInterface) {
    await queryInterface.dropTable('preferences');
  },
};
