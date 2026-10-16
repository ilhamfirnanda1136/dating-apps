'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('matches', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      user_a_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      user_b_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      status: {
        type: Sequelize.ENUM('active', 'unmatched', 'blocked'),
        allowNull: false,
        defaultValue: 'active',
      },
      matched_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addConstraint('matches', {
      fields: ['user_a_id', 'user_b_id'],
      type: 'unique',
      name: 'uq_matches_pair',
    });
    await queryInterface.addIndex('matches', ['user_b_id', 'status'], { name: 'idx_matches_user_b' });
    // MySQL tidak mengizinkan CHECK pada kolom FK ber-CASCADE; user_a_id < user_b_id dijaga di model Match.
  },

  async down(queryInterface) {
    await queryInterface.dropTable('matches');
  },
};
