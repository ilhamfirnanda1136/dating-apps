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

export class Message extends Model<InferAttributes<Message>, InferCreationAttributes<Message>> {
  declare id: CreationOptional<string>;
  declare match_id: ForeignKey<Match['id']>;
  declare sender_id: ForeignKey<User['id']>;
  declare reply_to_id: CreationOptional<string | null>;
  declare content: CreationOptional<string | null>;
  declare media_url: CreationOptional<string | null>;
  declare is_read: CreationOptional<boolean>;
  declare sent_at: CreationOptional<Date>;
}

Message.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    match_id: { type: DataTypes.UUID, allowNull: false },
    sender_id: { type: DataTypes.UUID, allowNull: false },
    reply_to_id: { type: DataTypes.UUID, allowNull: true },
    content: { type: DataTypes.TEXT, allowNull: true },
    media_url: { type: DataTypes.TEXT, allowNull: true },
    is_read: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    sent_at: DataTypes.DATE(3),
  },
  {
    sequelize,
    tableName: 'messages',
    createdAt: 'sent_at',
    updatedAt: false,
  },
);
