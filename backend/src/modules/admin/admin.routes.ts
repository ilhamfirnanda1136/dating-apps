import { Router, type Request, type Response } from 'express';
import { Op, type WhereOptions } from 'sequelize';
import { z } from 'zod';
import { authenticate } from '../../common/middlewares/authenticate';
import { requireRole } from '../../common/middlewares/require-role';
import { User } from '../../models';
import { USER_ROLES, USER_STATUSES } from '../../models/user.model';

const listUsersQuery = z.object({
  q: z.string().trim().min(1).optional(),
  status: z.enum(USER_STATUSES).optional(),
  role: z.enum(USER_ROLES).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const adminRouter = Router();

adminRouter.use(authenticate, requireRole('admin'));

adminRouter.get('/users', async (req: Request, res: Response) => {
  const query = listUsersQuery.parse(req.query);

  const where: WhereOptions = {};
  if (query.status) Object.assign(where, { status: query.status });
  if (query.role) Object.assign(where, { role: query.role });
  if (query.q) {
    Object.assign(where, {
      [Op.or]: [
        { email: { [Op.like]: `%${query.q}%` } },
        { phone: { [Op.like]: `%${query.q}%` } },
        { '$profile.full_name$': { [Op.like]: `%${query.q}%` } },
      ],
    });
  }

  const { rows, count } = await User.findAndCountAll({
    where,
    include: [{ association: 'profile', attributes: ['full_name', 'gender', 'birth_date', 'city', 'is_verified'] }],
    order: [['created_at', 'DESC']],
    limit: query.limit,
    offset: (query.page - 1) * query.limit,
    subQuery: false,
  });

  res.json({
    data: rows,
    meta: { page: query.page, limit: query.limit, total: count, total_pages: Math.ceil(count / query.limit) },
  });
});
