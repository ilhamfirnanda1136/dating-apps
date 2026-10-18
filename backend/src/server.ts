import { app } from './app';
import { env } from './config/env';
import { sequelize } from './models';
import { initWebSocketServer } from './websocket/socket.server';

async function main() {
  await sequelize.authenticate();
  console.log(`Terhubung ke MySQL ${env.DB_HOST}:${env.DB_PORT}/${env.DB_NAME}`);

  const server = app.listen(env.PORT, () => {
    console.log(`Server berjalan di http://localhost:${env.PORT}`);
  });

  initWebSocketServer(server);

  const shutdown = (signal: string) => {
    console.log(`${signal} diterima, mematikan server...`);
    server.close(async () => {
      await sequelize.close();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((err) => {
  console.error('Gagal menjalankan server:', err);
  process.exit(1);
});
