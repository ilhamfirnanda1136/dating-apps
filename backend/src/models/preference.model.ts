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

export class Preference extends Model<InferAttributes<Preference>, InferCreationAttributes<Preference>> {
  declare id: CreationOptional<string>;
  declare user_id: ForeignKey<User['id']>;
  declare interested_in: string;
  declare min_age: CreationOptional<number>;
  declare max_age: CreationOptional<number>;
  declare max_distance_km: CreationOptional<number>;
  declare created_at: CreationOptional<Date>;
  declare updated_at: CreationOptional<Date>;
}

Preference.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    interested_in: { type: DataTypes.STRING(20), allowNull: false },
    min_age: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 18, validate: { min: 18 } },
    max_age: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 99 },
    max_distance_km: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 50 },
    created_at: DataTypes.DATE,
    updated_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'preferences',
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  },
);
