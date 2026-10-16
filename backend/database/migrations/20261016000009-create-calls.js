'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('calls', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      match_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'matches', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      caller_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      call_type: { type: Sequelize.ENUM('audio', 'video'), allowNull: false },
      status: {
        type: Sequelize.ENUM('ringing', 'answered', 'missed', 'rejected', 'ended'),
        allowNull: false,
        defaultValue: 'ringing',
      },
      duration_sec: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      started_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('calls', ['match_id', 'started_at'], { name: 'idx_calls_match_time' });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('calls');
  },
};
