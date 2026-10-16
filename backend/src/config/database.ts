import { Sequelize } from 'sequelize';
import { env } from './env';

export const sequelize = new Sequelize(env.DB_NAME, env.DB_USER, env.DB_PASS, {
  host: env.DB_HOST,
  port: env.DB_PORT,
  dialect: 'mysql',
  timezone: '+00:00',
  logging: env.NODE_ENV === 'development' ? (sql) => console.log(sql) : false,
  pool: { max: 10, min: 0, idle: 10_000, acquire: 30_000 },
  define: {
    underscored: true,
    charset: 'utf8mb4',
    collate: 'utf8mb4_unicode_ci',
  },
});
