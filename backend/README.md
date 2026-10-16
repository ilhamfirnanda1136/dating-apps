# Backend Klik

API REST Express 5 + TypeScript + Sequelize + MySQL. Dokumentasi lengkap (setup, API, seeder, aturan bisnis) ada di [README akar repo](../README.md).

```bash
cp .env.example .env
npm install
npm run db:migrate
npm run db:seed
npm run dev
```

Server: `http://localhost:3000`  
Health: `GET /health`  
API: `http://localhost:3000/api/v1`

Spek produk: [`aidocs/spesifikasi-backend-aplikasi-kencan.md`](../aidocs/spesifikasi-backend-aplikasi-kencan.md).
