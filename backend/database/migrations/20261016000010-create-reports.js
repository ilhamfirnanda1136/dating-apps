'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('reports', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      reporter_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      reported_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      },
      reason: { type: Sequelize.STRING(50), allowNull: false },
      detail: { type: Sequelize.TEXT, allowNull: true },
      status: {
        type: Sequelize.ENUM('open', 'reviewing', 'resolved', 'dismissed'),
        allowNull: false,
        defaultValue: 'open',
      },
      handled_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'users', key: 'id' },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
      },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('reports', ['status', 'created_at'], { name: 'idx_reports_status' });
    await queryInterface.addIndex('reports', ['reported_id'], { name: 'idx_reports_reported' });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('reports');
  },
};
