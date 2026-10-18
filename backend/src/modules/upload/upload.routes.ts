import { Router, type Request, type Response } from 'express';
import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { authenticate } from '../../common/middlewares/authenticate';
import { AppError } from '../../common/errors';
import { env } from '../../config/env';

export const uploadRouter = Router();

uploadRouter.use(authenticate);

const UPLOAD_ROOT = path.join(__dirname, '../../../uploads');

uploadRouter.post('/', async (req: Request, res: Response) => {
  const { file, base64, filename } = req.body ?? {};
  const raw = (file || base64) as string | undefined;

  if (!raw || typeof raw !== 'string') {
    throw AppError.badRequest('File gambar tidak ditemukan');
  }

  // Deteksi ekstensi file dari data URL (contoh: data:image/png;base64,...)
  let ext = 'jpg';
  let cleanBase64 = raw;

  const match = raw.match(/^data:image\/([a-zA-Z0-9+.-]+);base64,(.+)$/);
  if (match) {
    ext = match[1] === 'jpeg' ? 'jpg' : match[1];
    cleanBase64 = match[2];
  } else if (filename && typeof filename === 'string') {
    const parsedExt = path.extname(filename).replace('.', '');
    if (parsedExt) ext = parsedExt;
  }

  const buffer = Buffer.from(cleanBase64, 'base64');
  if (buffer.length === 0) {
    throw AppError.badRequest('Format gambar tidak valid');
  }

  const chatDir = path.join(UPLOAD_ROOT, 'chat');
  if (!fs.existsSync(chatDir)) {
    fs.mkdirSync(chatDir, { recursive: true });
  }

  const newFileName = `${randomUUID()}.${ext}`;
  const filePath = path.join(chatDir, newFileName);
  fs.writeFileSync(filePath, buffer);

  // Buat URL yang dapat diakses oleh browser/aplikasi
  const protocol = req.protocol;
  const host = req.get('host') || `localhost:${env.PORT}`;
  const fileUrl = `${protocol}://${host}/uploads/chat/${newFileName}`;

  res.status(201).json({
    data: {
      url: fileUrl,
      filename: newFileName,
      size: buffer.length,
    },
  });
});
