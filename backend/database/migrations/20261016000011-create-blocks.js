'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('blocks', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      blocker_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      blocked_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addConstraint('blocks', {
      fields: ['blocker_id', 'blocked_id'],
      type: 'unique',
      name: 'uq_blocks_pair',
    });
    await queryInterface.addIndex('blocks', ['blocked_id'], { name: 'idx_blocks_blocked' });
    // MySQL tidak mengizinkan CHECK pada kolom FK ber-CASCADE; blocker_id <> blocked_id dijaga di model Block.
  },

  async down(queryInterface) {
    await queryInterface.dropTable('blocks');
  },
};
