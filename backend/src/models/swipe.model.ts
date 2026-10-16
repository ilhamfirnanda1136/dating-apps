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

export const SWIPE_ACTIONS = ['like', 'pass', 'super_like'] as const;
export type SwipeAction = (typeof SWIPE_ACTIONS)[number];

export class Swipe extends Model<InferAttributes<Swipe>, InferCreationAttributes<Swipe>> {
  declare id: CreationOptional<string>;
  declare swiper_id: ForeignKey<User['id']>;
  declare target_id: ForeignKey<User['id']>;
  declare action: SwipeAction;
  declare created_at: CreationOptional<Date>;
}

Swipe.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    swiper_id: { type: DataTypes.UUID, allowNull: false },
    target_id: { type: DataTypes.UUID, allowNull: false },
    action: { type: DataTypes.ENUM(...SWIPE_ACTIONS), allowNull: false },
    created_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'swipes',
    createdAt: 'created_at',
    updatedAt: false,
    validate: {
      notSelf(this: Swipe) {
        if (this.swiper_id === this.target_id) throw new Error('Tidak bisa swipe diri sendiri');
      },
    },
  },
);
