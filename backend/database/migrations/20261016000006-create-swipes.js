'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('swipes', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      swiper_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      target_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      action: { type: Sequelize.ENUM('like', 'pass', 'super_like'), allowNull: false },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addConstraint('swipes', {
      fields: ['swiper_id', 'target_id'],
      type: 'unique',
      name: 'uq_swipes_pair',
    });
    await queryInterface.addIndex('swipes', ['target_id', 'action'], { name: 'idx_swipes_target' });
    await queryInterface.addIndex('swipes', ['swiper_id', 'created_at'], { name: 'idx_swipes_swiper_time' });
    // MySQL tidak mengizinkan CHECK pada kolom FK ber-CASCADE; swiper_id <> target_id dijaga di model Swipe.
  },

  async down(queryInterface) {
    await queryInterface.dropTable('swipes');
  },
};
