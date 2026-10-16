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

export class Block extends Model<InferAttributes<Block>, InferCreationAttributes<Block>> {
  declare id: CreationOptional<string>;
  declare blocker_id: ForeignKey<User['id']>;
  declare blocked_id: ForeignKey<User['id']>;
  declare created_at: CreationOptional<Date>;
}

Block.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    created_at: DataTypes.DATE,
  },
  {
    sequelize,
    tableName: 'blocks',
    createdAt: 'created_at',
    updatedAt: false,
    validate: {
      notSelf(this: Block) {
        if (this.blocker_id === this.blocked_id) throw new Error('Tidak bisa memblokir diri sendiri');
      },
    },
  },
);
