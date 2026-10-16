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

export const DEVICE_PLATFORMS = ['android', 'ios', 'web'] as const;

export class Device extends Model<InferAttributes<Device>, InferCreationAttributes<Device>> {
  declare id: CreationOptional<string>;
  declare user_id: ForeignKey<User['id']>;
  declare fcm_token: string;
  declare platform: (typeof DEVICE_PLATFORMS)[number];
  declare last_seen_at: CreationOptional<Date | null>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;
}

Device.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    fcm_token: { type: DataTypes.STRING(255), allowNull: false, unique: true },
    platform: { type: DataTypes.ENUM(...DEVICE_PLATFORMS), allowNull: false },
    last_seen_at: { type: DataTypes.DATE, allowNull: true },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'devices',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
