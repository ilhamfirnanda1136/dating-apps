import http from 'http';
import { WebSocket, WebSocketServer } from 'ws';
import { URL } from 'url';
import { verifyAccessToken } from '../modules/auth/token.service';
import { Match, Message, Notification, Profile, User } from '../models';
import { toPublicProfile } from '../modules/common/public-profile';

interface AuthenticatedWebSocket extends WebSocket {
  userId?: string;
  isAlive?: boolean;
}

const userSockets = new Map<string, Set<AuthenticatedWebSocket>>();
let wss: WebSocketServer | null = null;

export function initWebSocketServer(server: http.Server) {
  wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws: AuthenticatedWebSocket, req: http.IncomingMessage) => {
    ws.isAlive = true;

    // Coba autentikasi via query string: ws://localhost:3000/ws?token=<JWT>
    try {
      const parsedUrl = new URL(req.url ?? '', `http://${req.headers.host || 'localhost'}`);
      const token = parsedUrl.searchParams.get('token');
      if (token) {
        const payload = verifyAccessToken(token);
        attachUser(ws, payload.sub);
      }
    } catch {
      // Token tidak valid atau tidak ada di query, tunggu pesan auth
    }

    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', async (raw: string | Buffer) => {
      try {
        const text = typeof raw === 'string' ? raw : raw.toString('utf-8');
        const data = JSON.parse(text);
        await handleSocketMessage(ws, data);
      } catch (err) {
        console.error('[WebSocket] Error memproses pesan:', err);
      }
    });

    ws.on('close', () => {
      if (ws.userId) {
        detachUser(ws, ws.userId);
      }
    });

    ws.on('error', (err) => {
      console.error('[WebSocket] Error socket:', err);
    });
  });

  // Heartbeat ping interval setiap 30 detik
  const interval = setInterval(() => {
    if (!wss) return;
    for (const ws of wss.clients as Set<AuthenticatedWebSocket>) {
      if (ws.isAlive === false) {
        if (ws.userId) detachUser(ws, ws.userId);
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, 30000);

  wss.on('close', () => {
    clearInterval(interval);
  });

  console.log('WebSocket Server aktif di path /ws');
  return wss;
}

function attachUser(ws: AuthenticatedWebSocket, userId: string) {
  ws.userId = userId;
  if (!userSockets.has(userId)) {
    userSockets.set(userId, new Set());
  }
  userSockets.get(userId)!.add(ws);
  ws.send(JSON.stringify({ type: 'authenticated', user_id: userId }));
}

function detachUser(ws: AuthenticatedWebSocket, userId: string) {
  const sockets = userSockets.get(userId);
  if (sockets) {
    sockets.delete(ws);
    if (sockets.size === 0) {
      userSockets.delete(userId);
    }
  }
}

async function handleSocketMessage(ws: AuthenticatedWebSocket, payload: any) {
  const type = payload?.type;

  // Autentikasi via pesan awal
  if (type === 'auth') {
    const token = payload?.token;
    if (typeof token === 'string') {
      try {
        const decoded = verifyAccessToken(token);
        attachUser(ws, decoded.sub);
      } catch {
        ws.send(JSON.stringify({ type: 'error', message: 'Token tidak valid' }));
      }
    }
    return;
  }

  // Ping / pong
  if (type === 'ping') {
    ws.send(JSON.stringify({ type: 'pong' }));
    return;
  }

  // Semua aksi berikutnya memerlukan autentikasi
  if (!ws.userId) {
    ws.send(JSON.stringify({ type: 'error', message: 'Belum terautentikasi' }));
    return;
  }

  const userId = ws.userId;

  // Kirim pesan chat real-time
  if (type === 'send_message') {
    const matchId = String(payload.match_id || '');
    const content = String(payload.content || '').trim();
    const mediaUrl = typeof payload.media_url === 'string' ? payload.media_url.trim() : null;
    const replyToId = typeof payload.reply_to_id === 'string' ? payload.reply_to_id : null;
    if (!matchId || (!content && !mediaUrl)) return;

    const match = await Match.findByPk(matchId);
    if (!match || (match.user_a_id !== userId && match.user_b_id !== userId) || match.status !== 'active') {
      ws.send(JSON.stringify({ type: 'error', message: 'Match tidak valid atau tidak aktif' }));
      return;
    }

    let validReplyTo: Message | null = null;
    if (replyToId) {
      validReplyTo = await Message.findOne({
        where: { id: replyToId, match_id: match.id },
      });
    }

    const message = await Message.create({
      match_id: match.id,
      sender_id: userId,
      content: content || null,
      media_url: mediaUrl,
      reply_to_id: validReplyTo ? validReplyTo.id : null,
    });

    const otherId = match.user_a_id === userId ? match.user_b_id : match.user_a_id;

    await Notification.create({
      user_id: otherId,
      type: 'message',
      title: 'Pesan baru',
      body: (content || (mediaUrl ? '📷 Foto' : '')).slice(0, 140),
      data: { match_id: match.id, sender_id: userId },
    });

    const replyInfo = validReplyTo
      ? {
          id: validReplyTo.id,
          content: validReplyTo.content,
          media_url: validReplyTo.media_url,
          sender_id: validReplyTo.sender_id,
        }
      : null;

    notifyNewMessage(
      match.id,
      userId,
      {
        id: message.id,
        content: message.content,
        media_url: message.media_url,
        reply_to_id: message.reply_to_id,
        reply_to: replyInfo
          ? {
              ...replyInfo,
              is_me: replyInfo.sender_id === userId,
            }
          : null,
        is_read: message.is_read,
        sent_at: message.sent_at,
      },
      otherId,
    );
    return;
  }

  // Indikator sedang mengetik (typing indicator)
  if (type === 'typing') {
    const matchId = String(payload.match_id || '');
    const isTyping = Boolean(payload.is_typing);
    if (!matchId) return;

    const match = await Match.findByPk(matchId);
    if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) return;

    const otherId = match.user_a_id === userId ? match.user_b_id : match.user_a_id;
    sendToUser(otherId, {
      type: 'typing',
      data: {
        match_id: matchId,
        user_id: userId,
        is_typing: isTyping,
      },
    });
    return;
  }

  // Tandai pesan sudah dibaca
  if (type === 'mark_read') {
    const matchId = String(payload.match_id || '');
    if (!matchId) return;

    const match = await Match.findByPk(matchId);
    if (!match || (match.user_a_id !== userId && match.user_b_id !== userId)) return;

    await Message.update(
      { is_read: true },
      { where: { match_id: match.id, sender_id: match.user_a_id === userId ? match.user_b_id : match.user_a_id, is_read: false } },
    );

    const otherId = match.user_a_id === userId ? match.user_b_id : match.user_a_id;
    sendToUser(otherId, {
      type: 'messages_read',
      data: {
        match_id: matchId,
        reader_id: userId,
      },
    });
  }
}

export function sendToUser(userId: string, event: object) {
  const sockets = userSockets.get(userId);
  if (!sockets || sockets.size === 0) return false;
  const message = JSON.stringify(event);
  for (const ws of sockets) {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(message);
    }
  }
  return true;
}

export function notifyNewMessage(
  matchId: string,
  senderId: string,
  message: {
    id: string;
    content?: string | null;
    media_url?: string | null;
    reply_to_id?: string | null;
    reply_to?: { id: string; content?: string | null; media_url?: string | null; is_me: boolean } | null;
    is_read: boolean;
    sent_at: Date;
  },
  otherId: string,
) {
  const content = message.content ?? '';

  // Kirim ke penerima (is_me = false)
  sendToUser(otherId, {
    type: 'new_message',
    data: {
      match_id: matchId,
      message: {
        ...message,
        content,
        reply_to: message.reply_to
          ? {
              ...message.reply_to,
              is_me: !message.reply_to.is_me,
            }
          : null,
        is_me: false,
      },
    },
  });

  // Kirim konfirmasi ke pengirim (is_me = true)
  sendToUser(senderId, {
    type: 'new_message',
    data: {
      match_id: matchId,
      message: {
        ...message,
        content,
        is_me: true,
      },
    },
  });
}

export async function notifyNewMatch(matchId: string, userId1: string, userId2: string) {
  const [userA, userB] = await Promise.all([
    User.findByPk(userId1, {
      include: [
        { association: 'profile' },
        { association: 'photos', separate: true, order: [['sort_order', 'ASC']] },
      ],
    }),
    User.findByPk(userId2, {
      include: [
        { association: 'profile' },
        { association: 'photos', separate: true, order: [['sort_order', 'ASC']] },
      ],
    }),
  ]);

  if (userA && userB) {
    sendToUser(userId1, {
      type: 'new_match',
      data: {
        match_id: matchId,
        user: toPublicProfile(userB),
      },
    });

    sendToUser(userId2, {
      type: 'new_match',
      data: {
        match_id: matchId,
        user: toPublicProfile(userA),
      },
    });
  }
}
