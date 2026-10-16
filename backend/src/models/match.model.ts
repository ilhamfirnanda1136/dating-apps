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

export const MATCH_STATUSES = ['active', 'unmatched', 'blocked'] as const;
export type MatchStatus = (typeof MATCH_STATUSES)[number];

export class Match extends Model<InferAttributes<Match>, InferCreationAttributes<Match>> {
  declare id: CreationOptional<string>;
  declare user_a_id: ForeignKey<User['id']>;
  declare user_b_id: ForeignKey<User['id']>;
  declare status: CreationOptional<MatchStatus>;
  declare matched_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;

  /** Pasangan selalu disimpan dengan user_a_id < user_b_id. */
  static orderPair(userId1: string, userId2: string): [string, string] {
    return userId1 < userId2 ? [userId1, userId2] : [userId2, userId1];
  }
}

Match.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    user_a_id: { type: DataTypes.UUID, allowNull: false },
    user_b_id: { type: DataTypes.UUID, allowNull: false },
    status: { type: DataTypes.ENUM(...MATCH_STATUSES), allowNull: false, defaultValue: 'active' },
    matched_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'matches',
    createdAt: 'matched_at',
    updatedAt: 'updated_at',
    validate: {
      orderedPair(this: Match) {
        if (!(this.user_a_id < this.user_b_id)) throw new Error('user_a_id harus lebih kecil dari user_b_id');
      },
    },
  },
);
