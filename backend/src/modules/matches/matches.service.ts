import { Op, type Includeable } from 'sequelize';
import { AppError } from '../../common/errors';
import { Match, Message, Notification, User } from '../../models';
import { toPublicProfile } from '../common/public-profile';
import { notifyNewMessage, sendToUser } from '../../websocket/socket.server';

const USER_INCLUDE: Includeable[] = [
  { association: 'profile' },
  { association: 'photos', separate: true, order: [['sort_order', 'ASC']] },
];

async function loadMatchForUser(matchId: string, userId: string) {
  const match = await Match.findByPk(matchId);
  if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) {
    throw AppError.notFound('Match tidak ditemukan');
  }
  if (match.status !== 'active') throw AppError.forbidden('Match tidak aktif');
  return match;
}

async function otherUser(match: Match, viewerId: string) {
  const otherId = match.user_a_id === viewerId ? match.user_b_id : match.user_a_id;
  const user = await User.findByPk(otherId, { include: USER_INCLUDE });
  if (!user) throw AppError.notFound('Pengguna tidak ditemukan');
  return user;
}

export async function listMatches(viewerId: string) {
  const matches = await Match.findAll({
    where: {
      status: 'active',
      [Op.or]: [{ user_a_id: viewerId }, { user_b_id: viewerId }],
    },
    order: [['matched_at', 'DESC']],
  });

  return Promise.all(
    matches.map(async (match) => {
      const user = await otherUser(match, viewerId);
      const lastMessage = await Message.findOne({
        where: { match_id: match.id },
        order: [['sent_at', 'DESC']],
      });
      const unread = await Message.count({
        where: { match_id: match.id, sender_id: { [Op.ne]: viewerId }, is_read: false },
      });
      return {
        id: match.id,
        matched_at: match.matched_at,
        unread,
        user: toPublicProfile(user),
        last_message: lastMessage
          ? {
              id: lastMessage.id,
              content: lastMessage.content,
              is_me: lastMessage.sender_id === viewerId,
              is_read: lastMessage.is_read,
              sent_at: lastMessage.sent_at,
            }
          : null,
      };
    }),
  );
}

export async function unmatch(viewerId: string, matchId: string) {
  const match = await loadMatchForUser(matchId, viewerId);
  match.status = 'unmatched';
  await match.save();
}

export async function listMessages(viewerId: string, matchId: string, before?: string, limit = 30) {
  const match = await loadMatchForUser(matchId, viewerId);
  const where: Record<string, unknown> = { match_id: match.id };
  if (before) where.sent_at = { [Op.lt]: new Date(before) };

  const rows = await Message.findAll({
    where,
    order: [['sent_at', 'DESC']],
    limit: Math.min(Math.max(limit, 1), 100),
    include: [
      {
        association: 'replyTo',
        attributes: ['id', 'content', 'media_url', 'sender_id'],
      },
    ],
  });

  return rows.reverse().map((message) => {
    const reply = (message as any).replyTo;
    return {
      id: message.id,
      content: message.content,
      media_url: message.media_url,
      reply_to_id: message.reply_to_id,
      reply_to: reply
        ? {
            id: reply.id,
            content: reply.content,
            media_url: reply.media_url,
            is_me: reply.sender_id === viewerId,
          }
        : null,
      is_me: message.sender_id === viewerId,
      is_read: message.is_read,
      sent_at: message.sent_at,
    };
  });
}

export async function sendMessage(
  viewerId: string,
  matchId: string,
  content: string,
  mediaUrl?: string | null,
  replyToId?: string | null,
) {
  const match = await loadMatchForUser(matchId, viewerId);
  const trimmed = content.trim();
  const trimmedMedia = mediaUrl?.trim() || null;
  if (!trimmed && !trimmedMedia) throw AppError.badRequest('Pesan tidak boleh kosong');

  let validReplyTo: Message | null = null;
  if (replyToId) {
    validReplyTo = await Message.findOne({
      where: { id: replyToId, match_id: match.id },
    });
  }

  const message = await Message.create({
    match_id: match.id,
    sender_id: viewerId,
    content: trimmed || null,
    media_url: trimmedMedia,
    reply_to_id: validReplyTo ? validReplyTo.id : null,
  });

  const replyInfo = validReplyTo
    ? {
        id: validReplyTo.id,
        content: validReplyTo.content,
        media_url: validReplyTo.media_url,
        is_me: validReplyTo.sender_id === viewerId,
      }
    : null;

  const otherId = match.user_a_id === viewerId ? match.user_b_id : match.user_a_id;
  await Notification.create({
    user_id: otherId,
    type: 'message',
    title: 'Pesan baru',
    body: (trimmed || (trimmedMedia ? '📷 Foto' : '')).slice(0, 140),
    data: { match_id: match.id, sender_id: viewerId },
  });

  notifyNewMessage(
    match.id,
    viewerId,
    {
      id: message.id,
      content: message.content,
      media_url: message.media_url,
      reply_to_id: message.reply_to_id,
      reply_to: replyInfo,
      is_read: message.is_read,
      sent_at: message.sent_at,
    },
    otherId,
  );

  return {
    id: message.id,
    content: message.content,
    media_url: message.media_url,
    reply_to_id: message.reply_to_id,
    reply_to: replyInfo,
    is_me: true,
    is_read: false,
    sent_at: message.sent_at,
  };
}

export async function markRead(viewerId: string, matchId: string) {
  const match = await loadMatchForUser(matchId, viewerId);
  await Message.update(
    { is_read: true },
    { where: { match_id: match.id, sender_id: { [Op.ne]: viewerId }, is_read: false } },
  );

  const otherId = match.user_a_id === viewerId ? match.user_b_id : match.user_a_id;
  sendToUser(otherId, {
    type: 'messages_read',
    data: {
      match_id: match.id,
      reader_id: viewerId,
    },
  });
}
