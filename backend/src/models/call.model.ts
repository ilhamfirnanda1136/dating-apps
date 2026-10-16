import {
  CreationOptional,
  DataTypes,
  ForeignKey,
  InferAttributes,
  InferCreationAttributes,
  Model,
} from 'sequelize';
import { sequelize } from '../config/database';
import type { Match } from './match.model';
import type { User } from './user.model';

export const CALL_TYPES = ['audio', 'video'] as const;
export const CALL_STATUSES = ['ringing', 'answered', 'missed', 'rejected', 'ended'] as const;

export class Call extends Model<InferAttributes<Call>, InferCreationAttributes<Call>> {
  declare id: CreationOptional<string>;
  declare match_id: ForeignKey<Match['id']>;
  declare caller_id: ForeignKey<User['id']>;
  declare call_type: (typeof CALL_TYPES)[number];
  declare status: CreationOptional<(typeof CALL_STATUSES)[number]>;
  declare duration_sec: CreationOptional<number>;
  declare started_at: CreationOptional<Date>;
}

Call.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    call_type: { type: DataTypes.ENUM(...CALL_TYPES), allowNull: false },
    status: { type: DataTypes.ENUM(...CALL_STATUSES), allowNull: false, defaultValue: 'ringing' },
    duration_sec: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    started_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'calls',
    createdAt: 'started_at',
    updatedAt: false,
  },
);
