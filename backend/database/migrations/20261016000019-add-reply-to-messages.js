'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('messages', 'reply_to_id', {
      type: Sequelize.UUID,
      allowNull: true,
      references: { model: 'messages', key: 'id' },
      onDelete: 'SET NULL',
      onUpdate: 'CASCADE',
      after: 'sender_id',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('messages', 'reply_to_id');
  },
};
