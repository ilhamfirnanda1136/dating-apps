export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly code: string = 'ERROR',
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
  }

  static badRequest(message = 'Permintaan tidak valid', details?: unknown) {
    return new AppError(400, message, 'BAD_REQUEST', details);
  }

  static unauthorized(message = 'Tidak terautentikasi') {
    return new AppError(401, message, 'UNAUTHORIZED');
  }

  static forbidden(message = 'Akses ditolak') {
    return new AppError(403, message, 'FORBIDDEN');
  }

  static notFound(message = 'Data tidak ditemukan') {
    return new AppError(404, message, 'NOT_FOUND');
  }

  static conflict(message = 'Data sudah ada') {
    return new AppError(409, message, 'CONFLICT');
  }
}
