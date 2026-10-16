import 'package:flutter/widgets.dart';

import '../api/dating_api.dart';
import '../models/chat.dart';
import '../models/user_profile.dart';

/// State daftar match + isi percakapan.
/// Satu instance hidup di [KlikApp] supaya pindah tab tidak kehilangan data.
class ChatStore extends ChangeNotifier {
  ChatStore({DatingApi? api}) : _api = api ?? DatingApi();

  final DatingApi _api;
  final List<Conversation> conversations = [];
  final List<UserProfile> newMatches = [];
  bool loading = false;
  String? error;

  bool isTyping(String conversationId) => false;

  int get unreadCount => conversations.fold(0, (sum, c) => sum + c.unread);

  void setActive(String? conversationId) {}

  /// Ambil semua match, lalu pisah:
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

  /// Buka chat dengan user yang sudah match. Lempar error jika belum match
  /// (tidak boleh membuat percakapan palsu di klien).
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
      await _api.markRead(conversation.id);
    } catch (_) {}
  }

  /// Gabungkan hasil GET dengan pesan yang baru terkirim di klien,
  /// supaya GET yang telat tidak menghapus bubble yang sudah tampil.
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

  Future<void> send(Conversation conversation, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final message = await _api.sendMessage(conversation.id, trimmed);
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
