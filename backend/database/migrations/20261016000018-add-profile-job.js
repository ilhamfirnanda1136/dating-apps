'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('profiles', 'job', {
      type: Sequelize.STRING(100),
      allowNull: true,
      after: 'bio',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('profiles', 'job');
  },
};
