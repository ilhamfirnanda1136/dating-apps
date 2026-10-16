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

export class RefreshToken extends Model<InferAttributes<RefreshToken>, InferCreationAttributes<RefreshToken>> {
  declare id: CreationOptional<string>;
  declare user_id: ForeignKey<User['id']>;
  declare token_hash: string;
  declare expires_at: Date;
  declare revoked_at: CreationOptional<Date | null>;
  declare user_agent: CreationOptional<string | null>;
  declare ip_address: CreationOptional<string | null>;
  declare created_at: CreationOptional<Date>;
}

RefreshToken.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    token_hash: { type: DataTypes.CHAR(64), allowNull: false, unique: true },
    expires_at: { type: DataTypes.DATE, allowNull: false },
    revoked_at: { type: DataTypes.DATE, allowNull: true },
    user_agent: { type: DataTypes.STRING(255), allowNull: true },
    ip_address: { type: DataTypes.STRING(45), allowNull: true },
    created_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'refresh_tokens',
    createdAt: 'created_at',
    updatedAt: false,
  },
);
