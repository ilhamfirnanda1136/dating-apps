import '../api/api_config.dart';
import 'user_profile.dart';

/// Data referensi pesan yang dibalas (quote).
class ChatMessageReply {
  ChatMessageReply({
    required this.id,
    required this.content,
    this.mediaUrl,
    this.senderId,
  });

  final String id;
  final String content;
  final String? mediaUrl;
  final String? senderId;

  factory ChatMessageReply.fromJson(Map<String, dynamic> json) {
    final rawMedia = (json['media_url'] as String?) ?? (json['mediaUrl'] as String?);
    return ChatMessageReply(
      id: (json['id'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      mediaUrl: rawMedia != null ? ApiConfig.resolveMediaUrl(rawMedia) : null,
      senderId: (json['sender_id'] as String?) ?? (json['senderId'] as String?),
    );
  }
}

/// Satu bubble chat. [isMe] menentukan rata kanan/kiri di UI.
class ChatMessage {
  ChatMessage({
    this.id,
    required this.text,
    required this.isMe,
    required this.sentAt,
    this.isRead = false,
    this.mediaUrl,
    this.replyToId,
    this.replyTo,
  });

  final String? id;
  final String text;
  final bool isMe;
  final DateTime sentAt;
  bool isRead;
  final String? mediaUrl;
  final String? replyToId;
  final ChatMessageReply? replyTo;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required bool fallbackIsMe}) {
    final rawMedia = (json['media_url'] as String?) ?? (json['mediaUrl'] as String?);
    final rawReply = json['reply_to'] as Map<String, dynamic>? ??
        json['replyTo'] as Map<String, dynamic>?;

    return ChatMessage(
      id: json['id'] as String?,
      text: (json['content'] as String?) ?? (json['text'] as String?) ?? '',
      isMe: json['is_me'] as bool? ?? fallbackIsMe,
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true,
      mediaUrl: rawMedia != null && rawMedia.isNotEmpty ? ApiConfig.resolveMediaUrl(rawMedia) : null,
      replyToId: (json['reply_to_id'] as String?) ?? (json['replyToId'] as String?),
      replyTo: rawReply != null ? ChatMessageReply.fromJson(rawReply) : null,
    );
  }
}

/// Satu thread chat = satu baris di tabel `matches`.
/// [id] adalah UUID match, bukan id user.
class Conversation {
  Conversation({
    required this.id,
    required this.user,
    List<ChatMessage>? messages,
    this.unread = 0,
  }) : messages = messages ?? [];

  final String id;
  final UserProfile user;
  final List<ChatMessage> messages;
  int unread;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      messages: [
        if (last != null) ChatMessage.fromJson(last, fallbackIsMe: last['is_me'] == true),
      ],
    );
  }
}
