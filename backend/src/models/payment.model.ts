import {
  CreationOptional,
  DataTypes,
  ForeignKey,
  InferAttributes,
  InferCreationAttributes,
  Model,
} from 'sequelize';
import { sequelize } from '../config/database';
import type { Subscription } from './subscription.model';

export const PAYMENT_STATUSES = ['pending', 'paid', 'failed', 'refunded'] as const;

export class Payment extends Model<InferAttributes<Payment>, InferCreationAttributes<Payment>> {
  declare id: CreationOptional<string>;
  declare subscription_id: ForeignKey<Subscription['id']>;
  declare amount: string;
  declare method: CreationOptional<string | null>;
  declare gateway_ref: CreationOptional<string | null>;
  declare status: CreationOptional<(typeof PAYMENT_STATUSES)[number]>;
  declare paid_at: CreationOptional<Date | null>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;
}

Payment.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    amount: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
    method: { type: DataTypes.STRING(30), allowNull: true },
    gateway_ref: { type: DataTypes.STRING(100), allowNull: true, unique: true },
    status: { type: DataTypes.ENUM(...PAYMENT_STATUSES), allowNull: false, defaultValue: 'pending' },
    paid_at: { type: DataTypes.DATE, allowNull: true },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'payments',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
