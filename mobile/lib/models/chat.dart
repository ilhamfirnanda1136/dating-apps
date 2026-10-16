import 'user_profile.dart';

/// Satu bubble chat. [isMe] menentukan rata kanan/kiri di UI.
class ChatMessage {
  ChatMessage({
    this.id,
    required this.text,
    required this.isMe,
    required this.sentAt,
    this.isRead = false,
  });

  final String? id;
  final String text;
  final bool isMe;
  final DateTime sentAt;
  bool isRead;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required bool fallbackIsMe}) {
    return ChatMessage(
      id: json['id'] as String?,
      text: (json['content'] as String?) ?? (json['text'] as String?) ?? '',
      isMe: json['is_me'] as bool? ?? fallbackIsMe,
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true,
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
