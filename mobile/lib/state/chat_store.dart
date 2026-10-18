import 'dart:async';
import 'package:flutter/widgets.dart';

import '../api/dating_api.dart';
import '../api/ws_client.dart';
import '../models/chat.dart';
import '../models/user_profile.dart';

/// State daftar match + isi percakapan dengan dukungan WebSocket real-time 2 arah.
/// Satu instance hidup di [FindLoveApp] supaya pindah tab tidak kehilangan data.
class ChatStore extends ChangeNotifier {
  ChatStore({DatingApi? api, WsClient? wsClient})
      : _api = api ?? DatingApi(),
        _ws = wsClient ?? WsClient() {
    _ws.onMessage = _handleWsMessage;
    _ws.onMatch = _handleWsMatch;
    _ws.onTyping = _handleWsTyping;
    _ws.onMessagesRead = _handleWsMessagesRead;
    _ws.onConnectionChange = (_) => notifyListeners();
  }

  final DatingApi _api;
  final WsClient _ws;
  final List<Conversation> conversations = [];
  final List<UserProfile> newMatches = [];
  bool loading = false;
  String? error;

  String? _activeConversationId;
  final Set<String> _typingMatches = {};
  final Map<String, Timer> _typingTimers = {};

  bool get isConnected => _ws.isConnected;
  bool isTyping(String conversationId) => _typingMatches.contains(conversationId);
  int get unreadCount => conversations.fold(0, (sum, c) => sum + c.unread);

  /// Menghubungkan WebSocket menggunakan token autentikasi pengguna.
  void initWebSocket(String token) {
    _ws.connect(token);
  }

  /// Memutuskan koneksi WebSocket saat logout.
  void disconnectWebSocket() {
    _ws.disconnect();
  }

  /// Mengatur percakapan yang sedang dibuka di layar.
  void setActive(String? conversationId) {
    _activeConversationId = conversationId;
    if (conversationId != null) {
      final conversation = byMatchId(conversationId);
      if (conversation != null && conversation.unread > 0) {
        markRead(conversation);
      }
    }
  }

  /// Mengirim status sedang mengetik melalui WebSocket.
  void sendTyping(String conversationId, bool isTyping) {
    _ws.sendTyping(matchId: conversationId, isTyping: isTyping);
  }

  void _handleWsMessage(String matchId, ChatMessage message) {
    final conversation = byMatchId(matchId);
    if (conversation != null) {
      final exists = conversation.messages.any((m) => m.id != null && m.id == message.id);
      if (!exists) {
        conversation.messages.add(message);
        if (_activeConversationId == matchId) {
          _api.markRead(matchId);
          _ws.sendMarkRead(matchId);
        } else if (!message.isMe) {
          conversation.unread++;
        }
        newMatches.removeWhere((u) => u.id == conversation.user.id);
        _pendingEmpty.removeWhere((c) => c.id == conversation.id);
        if (!conversations.contains(conversation)) conversations.insert(0, conversation);
        _moveToTop(conversation);
        notifyListeners();
      }
    } else {
      load();
    }
  }

  void _handleWsMatch(String matchId, UserProfile user) {
    addMatch(user, matchId: matchId);
  }

  void _handleWsTyping(String matchId, String userId, bool isTyping) {
    _typingTimers[matchId]?.cancel();
    if (isTyping) {
      _typingMatches.add(matchId);
      notifyListeners();
      _typingTimers[matchId] = Timer(const Duration(seconds: 4), () {
        _typingMatches.remove(matchId);
        notifyListeners();
      });
    } else {
      _typingMatches.remove(matchId);
      notifyListeners();
    }
  }

  void _handleWsMessagesRead(String matchId, String readerId) {
    final conversation = byMatchId(matchId);
    if (conversation != null) {
      for (final m in conversation.messages) {
        if (m.isMe) m.isRead = true;
      }
      notifyListeners();
    }
  }

  /// Ambil semua match dari REST API lalu pisah:
  /// - sudah ada pesan → [conversations]
  /// - belum chat → [newMatches] (strip "Match baru")
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.matches();
      conversations
        ..clear()
        ..addAll(rows.where((row) => row.lastMessage != null));
      newMatches
        ..clear()
        ..addAll(rows.where((row) => row.lastMessage == null).map((row) => row.user));
      _pendingEmpty = rows.where((row) => row.lastMessage == null).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Conversation> _pendingEmpty = [];

  /// Buka chat dengan user yang sudah match.
  Conversation openWith(UserProfile user) {
    final existing = conversations.where((c) => c.user.id == user.id).firstOrNull;
    if (existing != null) return existing;
    final pending = _pendingEmpty.where((c) => c.user.id == user.id).firstOrNull;
    if (pending != null) {
      newMatches.removeWhere((u) => u.id == user.id);
      conversations.insert(0, pending);
      notifyListeners();
      return pending;
    }
    throw StateError('Match tidak ditemukan');
  }

  Conversation? byMatchId(String matchId) {
    return conversations.where((c) => c.id == matchId).firstOrNull ??
        _pendingEmpty.where((c) => c.id == matchId).firstOrNull;
  }

  void addMatch(UserProfile user, {required String matchId}) {
    if (conversations.any((c) => c.id == matchId) || _pendingEmpty.any((c) => c.id == matchId)) return;
    final conversation = Conversation(id: matchId, user: user);
    _pendingEmpty.insert(0, conversation);
    newMatches.insert(0, user);
    notifyListeners();
  }

  Future<void> markRead(Conversation conversation) async {
    if (conversation.unread == 0) return;
    conversation.unread = 0;
    notifyListeners();
    try {
      _ws.sendMarkRead(conversation.id);
      await _api.markRead(conversation.id);
    } catch (_) {}
  }

  /// Gabungkan hasil GET dengan pesan yang baru terkirim di klien.
  Future<void> loadMessages(Conversation conversation) async {
    final rows = await _api.messages(conversation.id);
    final incomingIds = {for (final row in rows) row.id};
    final extras = conversation.messages
        .where((message) => message.id != null && !incomingIds.contains(message.id))
        .toList();
    conversation.messages
      ..clear()
      ..addAll(rows)
      ..addAll(extras);
    notifyListeners();
  }

  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
    String mimeType = 'image/jpeg',
  }) {
    return _api.uploadImage(bytes: bytes, filename: filename, mimeType: mimeType);
  }

  Future<void> send(
    Conversation conversation,
    String text, {
    String? mediaUrl,
    String? replyToId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;
    _ws.sendTyping(matchId: conversation.id, isTyping: false);
    final message = await _api.sendMessage(
      conversation.id,
      trimmed,
      mediaUrl: mediaUrl,
      replyToId: replyToId,
    );
    if (!conversation.messages.any((row) => row.id != null && row.id == message.id)) {
      conversation.messages.add(message);
    }
    newMatches.removeWhere((u) => u.id == conversation.user.id);
    _pendingEmpty.removeWhere((c) => c.id == conversation.id);
    if (!conversations.contains(conversation)) conversations.insert(0, conversation);
    _moveToTop(conversation);
    notifyListeners();
  }

  void _moveToTop(Conversation conversation) {
    conversations.remove(conversation);
    conversations.insert(0, conversation);
  }

  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _ws.dispose();
    super.dispose();
  }
}

/// Sama seperti [SessionScope], tapi untuk chat.
class ChatScope extends InheritedNotifier<ChatStore> {
  const ChatScope({super.key, required ChatStore store, required super.child})
      : super(notifier: store);

  static ChatStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatScope>()!.notifier!;

  static ChatStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChatScope>()!.notifier!;
}
