import {
  CreationOptional,
  DataTypes,
  ForeignKey,
  InferAttributes,
  InferCreationAttributes,
  Model,
  NonAttribute,
} from 'sequelize';
import { sequelize } from '../config/database';
import type { Plan } from './plan.model';
import type { User } from './user.model';

export const SUBSCRIPTION_STATUSES = ['pending', 'active', 'expired', 'cancelled'] as const;

export class Subscription extends Model<InferAttributes<Subscription>, InferCreationAttributes<Subscription>> {
  declare id: CreationOptional<string>;
  declare user_id: ForeignKey<User['id']>;
  declare plan_id: ForeignKey<Plan['id']>;
  declare status: CreationOptional<(typeof SUBSCRIPTION_STATUSES)[number]>;
  declare start_at: CreationOptional<Date | null>;
  declare end_at: CreationOptional<Date | null>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;

  declare plan?: NonAttribute<Plan>;
}

Subscription.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    status: { type: DataTypes.ENUM(...SUBSCRIPTION_STATUSES), allowNull: false, defaultValue: 'pending' },
    start_at: { type: DataTypes.DATE, allowNull: true },
    end_at: { type: DataTypes.DATE, allowNull: true },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'subscriptions',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
