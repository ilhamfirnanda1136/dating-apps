import {
  CreationOptional,
  DataTypes,
  ForeignKey,
  InferAttributes,
  InferCreationAttributes,
  Model,
} from 'sequelize';
import { sequelize } from '../config/database';
import type { User } from './user.model';

export const REPORT_STATUSES = ['open', 'reviewing', 'resolved', 'dismissed'] as const;

export class Report extends Model<InferAttributes<Report>, InferCreationAttributes<Report>> {
  declare id: CreationOptional<string>;
  declare reporter_id: ForeignKey<User['id']>;
  declare reported_id: ForeignKey<User['id']>;
  declare reason: string;
  declare detail: CreationOptional<string | null>;
  declare status: CreationOptional<(typeof REPORT_STATUSES)[number]>;
  declare handled_by: CreationOptional<ForeignKey<User['id']> | null>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;
}

Report.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    reason: { type: DataTypes.STRING(50), allowNull: false },
    detail: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.ENUM(...REPORT_STATUSES), allowNull: false, defaultValue: 'open' },
    handled_by: { type: DataTypes.UUID, allowNull: true },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'reports',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
