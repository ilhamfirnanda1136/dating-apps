# Klik — Aplikasi Kencan Online

Monorepo **Klik**: backend REST (Express + TypeScript + Sequelize + MySQL) dan aplikasi Flutter (Material 3, tema putih–pink) yang bisa dijalankan di **Chrome**.

Pengguna membuat akun, mengisi profil, swipe kandidat, match jika like-nya timbal balik, lalu chat. Data diambil dari database — bukan mock. Kalau suatu daftar masih kosong, UI menampilkan empty state (dan form URL foto jika profil belum punya gambar).

Spesifikasi awal ada di [`aidocs/spesifikasi-backend-aplikasi-kencan.md`](aidocs/spesifikasi-backend-aplikasi-kencan.md). Beberapa fitur spek (video call, payment gateway, FCM, unggah S3) belum dihubungkan; lihat [status fitur](#status-fitur).

---

## Daftar isi

1. [Fitur](#fitur)
2. [Status fitur](#status-fitur)
3. [Arsitektur](#arsitektur)
4. [Struktur folder](#struktur-folder)
5. [Prasyarat](#prasyarat)
6. [Menjalankan backend](#menjalankan-backend)
7. [Menjalankan Flutter](#menjalankan-flutter)
8. [Akun seeder](#akun-seeder)
9. [Aturan bisnis](#aturan-bisnis)
10. [API](#api)
11. [Autentikasi JWT](#autentikasi-jwt)
12. [Arsitektur Flutter](#arsitektur-flutter)
13. [Database](#database)
14. [Pengembangan](#pengembangan)
15. [Troubleshooting](#troubleshooting)

---

## Fitur

### Aplikasi (Flutter)

| Layar | Fungsi |
|---|---|
| Splash | Animasi merek sambil memulihkan sesi dari token tersimpan |
| Onboarding | Daftar / masuk |
| Register | Nama, email, password, tanggal lahir (≥ 18), gender, minat |
| Login | Email + password, JWT disimpan di SharedPreferences |
| Discover | Kartu swipe (like / pass / super like), filter usia & jarak |
| Match dialog | Tampil jika like **timbal balik** |
| Suka | Orang yang sudah like kamu + pilihan teratas dari discover |
| Pesan | Match baru + daftar percakapan |
| Chat | Riwayat dari API, icebreaker, kirim teks ke database |
| Notifikasi | Match / pesan dari tabel `notifications` |
| Profil | Kelengkapan, statistik, form URL foto jika belum ada foto |
| Edit profil | Nama, pekerjaan, kota, bio, minat, tambah foto URL |
| Pengaturan | Logout, preferensi (sebagian masih placeholder) |
| Klik Plus | UI paket premium (belum terhubung payment) |

Di **Chrome desktop** aplikasi dibungkus bingkai ponsel (`PhoneFrame`) agar layout HP tetap terbaca.

### Backend

- REST `/api/v1` + `GET /health`
- JWT access token (pendek) + refresh token (panjang, disimpan di `refresh_tokens`)
- Validasi body dengan Zod
- Rate limit login/register: 20 percobaan / 15 menit
- CORS + Helmet (`cross-origin` agar foto remote tampil di Flutter web)
- Migrasi Sequelize (18 file) + seeder admin, paket premium, user demo, 50 akun acak

---

## Status fitur

| Area | Status |
|---|---|
| Auth, profil, preferensi, foto URL | Siap |
| Discover, swipe, match, chat teks | Siap |
| Notifikasi in-app (tabel) | Siap |
| Admin daftar pengguna | Siap (API) |
| Upload foto ke S3 | Belum — foto lewat URL `https://...` |
| Chat realtime (WebSocket) | Belum — polling / muat ulang saat buka ruang chat |
| Video call | Skema `calls` ada, UI “segera hadir” |
| Blokir / laporkan | Tabel ada, belum di UI |
| Premium / payment gateway | Tabel `plans` + seeder, UI dummy |
| Push FCM / email | Belum |
| Verifikasi KTP / selfie | Tabel `verifications` ada, belum di UI |

---

## Arsitektur

```
┌─────────────────────┐     HTTP JSON      ┌──────────────────────┐
│  Flutter (Chrome /  │  /api/v1/...       │  Express 5 + TS      │
│  Android / iOS)     │  Bearer JWT        │  Zod + Helmet        │
│                     │ ◄────────────────► │                      │
│  SessionStore       │                    │  Sequelize 6         │
│  ChatStore          │                    │         ▼            │
│  DatingApi/AuthApi  │                    │  MySQL 8             │
└─────────────────────┘                    └──────────────────────┘
```

- Prefix API: `http://localhost:3000/api/v1`
- Respons sukses: `{ "data": ... }`
- Respons error: `{ "error": { "code", "message", "details?" } }`

Match **hanya** tercipta jika kedua pengguna memberi `like` atau `super_like` (bukan dari swipe kanan sepihak).

---

## Struktur folder

```
datingapp/
├── aidocs/                          # spek produk & ERD
│   └── spesifikasi-backend-aplikasi-kencan.md
├── backend/
│   ├── database/
│   │   ├── config.js                # sequelize-cli (baca .env)
│   │   ├── migrations/              # 18 migrasi MySQL
│   │   └── seeders/
│   ├── src/
│   │   ├── app.ts                   # Express, CORS, /health
│   │   ├── server.ts                # listen + graceful shutdown
│   │   ├── routes.ts                # susunan /api/v1
│   │   ├── config/                  # env + koneksi DB
│   │   ├── common/                  # error, middleware, util usia
│   │   ├── models/                  # Sequelize models
│   │   └── modules/                 # auth, users, discover, swipes, matches, ...
│   ├── .env.example
│   └── package.json
└── mobile/
    ├── lib/
    │   ├── main.dart                # runApp, SessionScope, ChatScope
    │   ├── api/                     # HTTP client, JWT, DatingApi
    │   ├── models/                  # Account, UserProfile, Conversation
    │   ├── state/                   # ChangeNotifier (session + chat)
    │   ├── screens/                 # splash, auth, discover, likes, chat, profil
    │   ├── widgets/                 # tombol, empty state, bingkai HP
    │   ├── theme/
    │   └── utils/
    ├── test/
    └── pubspec.yaml
```

Komentar di kode Flutter (`///`) memakai bahasa Indonesia agar mudah dipelajari.

---

## Prasyarat

| Perangkat | Versi yang dipakai di proyek ini |
|---|---|
| Node.js | 20+ (diuji 22) |
| MySQL | 8.x, port default `3306` |
| Flutter | 3.47+ / Dart 3.13+ (`sdk: ^3.13.5`) |
| Chrome | untuk `flutter run -d chrome` |

Pastikan MySQL berjalan dan user punya hak `CREATE DATABASE` jika memakai `npm run db:create`.

---

## Menjalankan backend

```bash
cd backend
cp .env.example .env
# isi DB_NAME, DB_USER, DB_PASS, JWT_ACCESS_SECRET (min. 16 karakter)
npm install
npm run db:create      # sekali: buat database
npm run db:migrate     # skema tabel
npm run db:seed        # admin, paket, Budi, 50 akun acak
npm run dev            # http://localhost:3000  (tsx watch)
```

Cek kesehatan:

```bash
curl http://localhost:3000/health
# { "status": "ok", "database": "up" }
```

### Variabel lingkungan (`backend/.env`)

| Nama | Wajib | Default | Keterangan |
|---|---|---|---|
| `NODE_ENV` | tidak | `development` | `development` / `test` / `production` |
| `PORT` | tidak | `3000` | Port HTTP |
| `DB_HOST` | tidak | `127.0.0.1` | Host MySQL |
| `DB_PORT` | tidak | `3306` | Port MySQL |
| `DB_NAME` | ya | — | Nama database |
| `DB_USER` | ya | — | User MySQL |
| `DB_PASS` | tidak | `""` | Password MySQL |
| `JWT_ACCESS_SECRET` | ya | — | Minimal 16 karakter, **ganti di production** |
| `JWT_ACCESS_EXPIRES_IN` | tidak | `15m` | Umur access token |
| `REFRESH_TOKEN_TTL_DAYS` | tidak | `30` | Umur refresh token |
| `CORS_ORIGIN` | tidak | `*` | Asal browser, atau daftar dipisah koma |
| `SEED_ADMIN_EMAIL` | seeder | `admin@datingapp.local` | Akun admin |
| `SEED_ADMIN_PASSWORD` | seeder | `Admin12345` | Password admin |

Jangan commit `.env`. Jangan pakai secret JWT yang sama dengan contoh di internet.

### Skrip npm backend

| Perintah | Fungsi |
|---|---|
| `npm run dev` | Server development dengan reload |
| `npm run build` | Compile TypeScript ke `dist/` |
| `npm start` | Jalankan `dist/server.js` |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run db:create` | Buat database |
| `npm run db:migrate` | Jalankan migrasi |
| `npm run db:migrate:undo` | Undo migrasi terakhir |
| `npm run db:migrate:reset` | Undo semua lalu migrate ulang (**hapus data**) |
| `npm run db:seed` | Jalankan semua seeder |
| `npm run db:seed:undo` | Undo semua seeder |
| `npx sequelize-cli db:seed --seed 20261016000004-random-users.js` | Seeder 50 akun saja |

---

## Menjalankan Flutter

Backend harus sudah hidup di `:3000`.

```bash
cd mobile
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Perangkat lain:

```bash
# Android emulator (localhost HP = 10.0.2.2)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# iOS simulator / desktop native
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

Kalau `--dart-define` tidak diisi, `ApiConfig` memakai:

- Web → `http://localhost:3000/api/v1`
- Android → `http://10.0.2.2:3000/api/v1`
- Lainnya → `http://127.0.0.1:3000/api/v1`

Setelah mengubah banyak file Dart, tekan **`R`** (hot **restart**) di terminal `flutter run`, bukan hanya `r` (hot reload).

Di Chrome, buka URL yang dicetak Flutter (bukan port 5173 Vue). Foto remote butuh Helmet CORP `cross-origin` (sudah diset di `backend/src/app.ts`).

---

## Akun seeder

Password semua akun demo: **`password123`**, kecuali admin.

| Email | Peran | Keterangan |
|---|---|---|
| `budi@mail.com` | user | Akun demo utama (laki-laki, cari perempuan) |
| `seed01@mail.com` … `seed50@mail.com` | user | 30 perempuan + 20 laki-laki, foto, bio, lokasi Jabodetabek |
| `admin@datingapp.local` | admin | Dari `SEED_ADMIN_*` di `.env` |

Seeder **tidak** membuat like ke Budi. Match hanya terjadi jika dua orang saling like.

Untuk login di app: splash → “Saya sudah punya akun” → `budi@mail.com` / `password123`.

---

## Aturan bisnis

### Discover

Kandidat yang ditampilkan:

- `role = user`, `status = active`
- Bukan diri sendiri, belum pernah di-swipe, tidak saling blokir
- Gender sesuai `preferences.interested_in` (`male` / `female` / `all`)
- Usia di antara `min_age`–`max_age`
- Preferensi **lawan** juga harus cocok dengan gender kita
- Jarak (Haversine) hanya dihitung jika **kedua** profil punya `latitude`/`longitude`; jika salah satu kosong, jarak tidak memfilter

Budi seeder belum punya koordinat, jadi filter jarak belum aktif sampai lokasi diisi (`PUT /me/location`).

### Swipe & match

- Aksi: `like` | `pass` | `super_like`
- Satu pasangan (`swiper_id`, `target_id`) hanya sekali (unique)
- Match dibuat hanya jika lawan sudah `like` / `super_like` kita
- Pasangan di `matches` disimpan terurut `user_a_id < user_b_id`
- Match memunculkan notifikasi tipe `match` untuk kedua belah pihak

### Chat

- Hanya anggota match aktif yang boleh baca/kirim
- Body: `{ "content": "..." }` 1–2000 karakter
- Pengirim lawan mendapat notifikasi tipe `message`
- `PATCH .../messages/read` menandai pesan lawan sebagai terbaca

### Foto

- Maksimal 6 foto per akun
- Foto pertama (atau `is_primary`) jadi avatar
- Validasi URL: harus `http://` atau `https://`

### Usia

Registrasi menolak usia di bawah 18 tahun (dihitung dari `birth_date`).

---

## API

Base: `http://localhost:3000/api/v1`  
Header terautentikasi: `Authorization: Bearer <access_token>`  
`Content-Type: application/json`

### Publik

| Method | Path | Keterangan |
|---|---|---|
| GET | `/health` | Status app + ping MySQL (tanpa prefix `/api/v1`) |
| POST | `/api/v1/auth/register` | Daftar |
| POST | `/api/v1/auth/login` | Masuk |
| POST | `/api/v1/auth/refresh` | Access token baru |

### Auth (Bearer)

| Method | Path | Keterangan |
|---|---|---|
| POST | `/auth/logout` | Cabut refresh token |

**Register**

```json
{
  "email": "sinta@mail.com",
  "password": "password123",
  "full_name": "Sinta Dewi",
  "birth_date": "1999-03-21",
  "gender": "female",
  "interested_in": "male",
  "phone": "+628123456789"
}
```

`phone` opsional. `gender`: `male` \| `female`. `interested_in`: `male` \| `female` \| `all`.

**Login**

```json
{ "email": "budi@mail.com", "password": "password123" }
```

**Contoh sukses auth** (`data.tokens` + `data.user`):

```json
{
  "data": {
    "user": { "id": "...", "email": "budi@mail.com", "profile": {}, "photos": [], "preference": {} },
    "tokens": { "access_token": "...", "refresh_token": "..." }
  }
}
```

### Profil (`/me`)

| Method | Path | Keterangan |
|---|---|---|
| GET | `/me` | Akun + profil + foto + preferensi |
| PUT | `/me/profile` | `full_name`, `bio`, `city`, `job`, `gender`, `birth_date` |
| PUT | `/me/location` | `latitude`, `longitude`, `city?` |
| GET | `/me/preferences` | Filter pencarian |
| PUT | `/me/preferences` | `interested_in`, `min_age`, `max_age`, `max_distance_km` |
| POST | `/me/photos` | `{ "url": "https://...", "is_primary": true }` |
| DELETE | `/me/photos/:id` | Hapus foto |

### Discover, swipe, likes

| Method | Path | Keterangan |
|---|---|---|
| GET | `/discover?limit=20` | Antrian kartu (maks. 50) |
| POST | `/swipes` | `{ "target_id": "<uuid>", "action": "like" }` |
| GET | `/likes` | Orang yang like kita dan belum match |

Respons swipe jika match:

```json
{
  "data": {
    "action": "like",
    "target_id": "...",
    "match": { "id": "...", "status": "active", "matched_at": "..." }
  }
}
```

Jika belum match, `match` bernilai `null`.

### Match & pesan

| Method | Path | Keterangan |
|---|---|---|
| GET | `/matches` | Daftar match + `last_message` + `unread` |
| DELETE | `/matches/:id` | Unmatch (`status = unmatched`) |
| GET | `/matches/:id/messages?limit=50&before=` | Riwayat (urut lama → baru) |
| POST | `/matches/:id/messages` | `{ "content": "Halo" }` → 201 |
| PATCH | `/matches/:id/messages/read` | Tandai terbaca (204) |

`:id` adalah **UUID match**, bukan UUID user.

### Notifikasi

| Method | Path | Keterangan |
|---|---|---|
| GET | `/notifications` | 50 terbaru |
| PATCH | `/notifications/:id/read` | Tandai terbaca |

### Admin (role `admin`)

| Method | Path | Keterangan |
|---|---|---|
| GET | `/admin/users?q=&status=&role=&page=1&limit=20` | Daftar pengguna + meta pagination |

### Kode error umum

| HTTP | `error.code` | Arti |
|---|---|---|
| 400 | `BAD_REQUEST` | Input / aturan bisnis (usia, swipe diri sendiri) |
| 401 | `UNAUTHORIZED` / `TOKEN_EXPIRED` / `INVALID_TOKEN` | Belum login atau JWT rusak |
| 403 | `FORBIDDEN` | Suspend / bukan admin / match tidak aktif |
| 404 | `NOT_FOUND` | Resource tidak ada |
| 409 | `CONFLICT` | Email duplikat, sudah swipe, dll. |
| 422 | `VALIDATION_ERROR` | Zod / Sequelize validation |
| 429 | `TOO_MANY_REQUESTS` | Rate limit auth |

---

## Autentikasi JWT

1. Login/register mengembalikan `access_token` + `refresh_token`.
2. Access token dikirim di `Authorization: Bearer ...`.
3. Jika 401, Flutter `ApiClient` memanggil `POST /auth/refresh` dengan refresh token, menyimpan pasangan baru, lalu mengulang request asli.
4. Logout mengirim refresh token ke server lalu menghapus penyimpanan lokal.

Access token sengaja berumur pendek (`15m`). Jangan taruh refresh token di query string.

---

## Arsitektur Flutter

```
KlikApp
 ├─ SessionScope (ChangeNotifier: login, /me, foto, preferensi)
 └─ ChatScope    (ChangeNotifier: match, pesan)
      └─ MaterialApp
           builder: PhoneFrame
           home: SplashScreen
                ├─ Onboarding → Login / Register
                └─ HomeShell (IndexedStack 4 tab)
                     Discover | Likes | Chat | Profil
```

| Lapisan | File | Tugas |
|---|---|---|
| UI | `lib/screens/`, `lib/widgets/` | Widget, form, empty state |
| State | `lib/state/session_store.dart`, `chat_store.dart` | `notifyListeners()` |
| API | `lib/api/dating_api.dart`, `auth_api.dart` | Mapping JSON ↔ model |
| HTTP | `lib/api/api_client.dart` | Bearer, refresh, error |
| Model | `lib/models/` | `Account`, `UserProfile`, `Conversation` |

Pola InheritedNotifier:

- `SessionScope.of(context)` — *listen*, widget rebuild saat data berubah
- `SessionScope.read(context)` — tanpa listen, cocok di `onPressed` / `initState`

Setelah `await`, selalu cek `mounted` sebelum memakai `context`.

Tes: `cd mobile && flutter test` (ChatStore, `Account.fromJson`, format waktu).

---

## Database

MySQL 8. Migrasi di `backend/database/migrations/`.

| Tabel | Isi |
|---|---|
| `users` | Akun, role, status, password bcrypt |
| `profiles` | Nama, lahir, gender, bio, job, kota, lat/lng, verified |
| `photos` | URL, urutan, primary |
| `preferences` | interested_in, usia, jarak |
| `swipes` | like / pass / super_like |
| `matches` | pasangan aktif / unmatched / blocked |
| `messages` | chat teks |
| `notifications` | in-app |
| `refresh_tokens` | sesi |
| `devices` | device push (siap, belum dipakai app) |
| `plans` / `subscriptions` / `payments` | premium |
| `blocks` / `reports` / `calls` / `verifications` | spek, belum UI |

Relasi anak memakai `ON DELETE CASCADE` ke `users`.

---

## Pengembangan

```bash
# Backend
cd backend && npm run typecheck && npm run dev

# Flutter
cd mobile && flutter analyze && flutter test
```

Migrasi baru:

```bash
cd backend
npm run migration:new -- add-kolom-xyz
# edit file di database/migrations/
npm run db:migrate
```

Model Sequelize ada di `backend/src/models/`. Setelah menambah asosiasi, daftarkan di `models/index.ts`.

---

## Troubleshooting

**`flutter run` tidak menampilkan kartu / data kosong**  
Pastikan seeder 50 akun sudah jalan dan login sebagai `budi@mail.com`. Budi mencari `female` — kartu adalah akun perempuan yang belum di-swipe. Tekan **R** (hot restart) setelah pull kode baru.

**Swipe langsung “It's a Match!”**  
Hanya jika lawan sudah like kamu. Seeder acak **tidak** mengisi like otomatis. Kalau masih terjadi, cek baris di `swipes` untuk `target_id` = Budi.

**Pesan tidak kelihatan setelah kirim**  
Pesan tersimpan di `messages` (UUID **match**, bukan user). Composer dinonaktifkan sampai riwayat selesai dimuat. Lihat tabel:

```sql
SELECT id, match_id, content, sent_at FROM messages ORDER BY sent_at DESC LIMIT 10;
```

**`Tidak bisa terhubung ke server`**  
`npm run dev` di `backend`, URL `--dart-define=API_BASE_URL=...` tepat, dan tidak ada sisa `DB_PORT=3307` di environment shell.

**Migrasi gagal / seeder admin duplikat**  
`db:seed` hanya menjalankan seeder yang belum tercatat di `sequelize_seeders`. Jangan jalankan ulang seeder admin secara manual jika email sudah ada.

**Foto tidak tampil di Chrome**  
URL harus publik (`https://...`). Helmet sudah `crossOriginResourcePolicy: cross-origin`. Cek CORS jika origin Flutter bukan `localhost`.

**401 terus-menerus**  
Access token kedaluwarsa dan refresh gagal. Logout lalu login lagi. Pastikan `JWT_ACCESS_SECRET` tidak berubah di tengah sesi.

**Rate limit login**  
Maksimal 20 percobaan / 15 menit per IP pada `/auth/login` dan `/auth/register`.

---

## Lisensi

ISC (backend). Aplikasi ini proyek pembelajaran / prototipe, bukan produk produksi siap rilis.
