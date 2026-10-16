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

export const VERIFICATION_TYPES = ['email', 'phone', 'ktp', 'selfie'] as const;
export const VERIFICATION_STATUSES = ['pending', 'approved', 'rejected'] as const;

export class Verification extends Model<InferAttributes<Verification>, InferCreationAttributes<Verification>> {
  declare id: CreationOptional<string>;
  declare user_id: ForeignKey<User['id']>;
  declare type: (typeof VERIFICATION_TYPES)[number];
  declare document_url: CreationOptional<string | null>;
  declare status: CreationOptional<(typeof VERIFICATION_STATUSES)[number]>;
  declare verified_at: CreationOptional<Date | null>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;
}

Verification.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    type: { type: DataTypes.ENUM(...VERIFICATION_TYPES), allowNull: false },
    document_url: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.ENUM(...VERIFICATION_STATUSES), allowNull: false, defaultValue: 'pending' },
    verified_at: { type: DataTypes.DATE, allowNull: true },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'verifications',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
