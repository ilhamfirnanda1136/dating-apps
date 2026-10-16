import { sequelize } from '../config/database';
import { User } from './user.model';
import { Profile } from './profile.model';
import { Photo } from './photo.model';
import { Preference } from './preference.model';
import { Verification } from './verification.model';
import { Swipe } from './swipe.model';
import { Match } from './match.model';
import { Message } from './message.model';
import { Call } from './call.model';
import { Report } from './report.model';
import { Block } from './block.model';
import { Plan } from './plan.model';
import { Subscription } from './subscription.model';
import { Payment } from './payment.model';
import { Notification } from './notification.model';
import { RefreshToken } from './refresh-token.model';
import { Device } from './device.model';

User.hasOne(Profile, { foreignKey: 'user_id', as: 'profile' });
Profile.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasOne(Preference, { foreignKey: 'user_id', as: 'preference' });
Preference.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(Photo, { foreignKey: 'user_id', as: 'photos' });
Photo.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(Verification, { foreignKey: 'user_id', as: 'verifications' });
Verification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(Swipe, { foreignKey: 'swiper_id', as: 'swipesGiven' });
User.hasMany(Swipe, { foreignKey: 'target_id', as: 'swipesReceived' });
Swipe.belongsTo(User, { foreignKey: 'swiper_id', as: 'swiper' });
Swipe.belongsTo(User, { foreignKey: 'target_id', as: 'target' });

Match.belongsTo(User, { foreignKey: 'user_a_id', as: 'userA' });
Match.belongsTo(User, { foreignKey: 'user_b_id', as: 'userB' });
Match.hasMany(Message, { foreignKey: 'match_id', as: 'messages' });
Match.hasMany(Call, { foreignKey: 'match_id', as: 'calls' });

Message.belongsTo(Match, { foreignKey: 'match_id', as: 'match' });
Message.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });

Call.belongsTo(Match, { foreignKey: 'match_id', as: 'match' });
Call.belongsTo(User, { foreignKey: 'caller_id', as: 'caller' });

Report.belongsTo(User, { foreignKey: 'reporter_id', as: 'reporter' });
Report.belongsTo(User, { foreignKey: 'reported_id', as: 'reported' });
Report.belongsTo(User, { foreignKey: 'handled_by', as: 'handler' });

Block.belongsTo(User, { foreignKey: 'blocker_id', as: 'blocker' });
Block.belongsTo(User, { foreignKey: 'blocked_id', as: 'blocked' });

Plan.hasMany(Subscription, { foreignKey: 'plan_id', as: 'subscriptions' });
User.hasMany(Subscription, { foreignKey: 'user_id', as: 'subscriptions' });
Subscription.belongsTo(Plan, { foreignKey: 'plan_id', as: 'plan' });
Subscription.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
Subscription.hasMany(Payment, { foreignKey: 'subscription_id', as: 'payments' });
Payment.belongsTo(Subscription, { foreignKey: 'subscription_id', as: 'subscription' });

User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(Device, { foreignKey: 'user_id', as: 'devices' });
Device.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

export {
  sequelize,
  User,
  Profile,
  Photo,
  Preference,
  Verification,
  Swipe,
  Match,
  Message,
  Call,
  Report,
  Block,
  Plan,
  Subscription,
  Payment,
  Notification,
  RefreshToken,
  Device,
};
