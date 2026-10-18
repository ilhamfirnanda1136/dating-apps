import 'dart:convert';
import '../models/account.dart';
import '../models/chat.dart';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Notifikasi dari GET /notifications.
/// [factory fromJson] adalah constructor yang mengubah JSON Map → objek Dart.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.matchId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? matchId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true,
      matchId: data is Map ? data['match_id'] as String? : null,
    );
  }
}

/// Hasil POST /swipes. [matched] true hanya jika backend mengembalikan match_id.
class SwipeResult {
  const SwipeResult({required this.matched, this.matchId});

  final bool matched;
  final String? matchId;
}

/// API fitur kencan: discover, swipe, match, chat, foto, preferensi.
class DatingApi {
  DatingApi({ApiClient? client, TokenStorage? storage})
      : _client = client ?? ApiClient(storage: storage);

  final ApiClient _client;

  /// Antrian kartu swipe. Query `?limit=` ikut di URL.
  Future<List<UserProfile>> discover({int limit = 20}) async {
    final body = await _client.get('/discover?limit=$limit');
    return _profiles(body['data']);
  }

  Future<List<UserProfile>> likes() async {
    final body = await _client.get('/likes');
    return _profiles(body['data']);
  }

  /// [action] harus `like`, `pass`, atau `super_like` (enum di backend).
  Future<SwipeResult> swipe({required String targetId, required String action}) async {
    final body = await _client.post('/swipes', body: {'target_id': targetId, 'action': action});
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final match = data['match'];
    final matchId = match is Map ? match['id']?.toString() : null;
    return SwipeResult(
      matched: matchId != null && matchId.isNotEmpty,
      matchId: matchId,
    );
  }

  Future<List<Conversation>> matches() async {
    final body = await _client.get('/matches');
    final rows = body['data'] as List<dynamic>? ?? [];
    return rows.whereType<Map<String, dynamic>>().map(Conversation.fromJson).toList();
  }

  Future<List<ChatMessage>> messages(String matchId) async {
    final body = await _client.get('/matches/$matchId/messages?limit=50');
    final rows = body['data'] as List<dynamic>? ?? [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => ChatMessage.fromJson(row, fallbackIsMe: row['is_me'] == true))
        .toList();
  }

  Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
    String mimeType = 'image/jpeg',
  }) async {
    final base64Data = base64Encode(bytes);
    final dataUri = 'data:$mimeType;base64,$base64Data';
    final body = await _client.post('/upload', body: {
      'image': dataUri,
      'filename': filename,
    });
    final data = body['data'];
    if (data is Map && data['url'] is String) {
      return data['url'] as String;
    }
    throw const ApiException('Gagal mengupload gambar');
  }

  Future<ChatMessage> sendMessage(
    String matchId,
    String content, {
    String? mediaUrl,
    String? replyToId,
  }) async {
    final payload = <String, dynamic>{'content': content};
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      payload['media_url'] = mediaUrl;
    }
    if (replyToId != null && replyToId.isNotEmpty) {
      payload['reply_to_id'] = replyToId;
    }
    final body = await _client.post('/matches/$matchId/messages', body: payload);
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException('Respons kirim pesan tidak valid');
    }
    return ChatMessage.fromJson(Map<String, dynamic>.from(data), fallbackIsMe: true);
  }

  Future<void> markRead(String matchId) => _client.patchEmpty('/matches/$matchId/messages/read');

  Future<void> markNotificationRead(String id) => _client.patchEmpty('/notifications/$id/read');

  Future<List<AppNotification>> notifications() async {
    final body = await _client.get('/notifications');
    final rows = body['data'] as List<dynamic>? ?? [];
    return rows.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
  }

  Future<Account> addPhoto(String url) async {
    final body = await _client.post('/me/photos', body: {'url': url});
    return Account.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Account> updatePreferences({
    required int minAge,
    required int maxAge,
    required int maxDistanceKm,
  }) async {
    await _client.put('/me/preferences', body: {
      'min_age': minAge,
      'max_age': maxAge,
      'max_distance_km': maxDistanceKm,
    });
    final me = await _client.get('/me');
    return Account.fromJson(me['data'] as Map<String, dynamic>);
  }

  /// JSON kadang bukan List; kita amankan dengan `?? []` lalu filter Map saja.
  List<UserProfile> _profiles(dynamic data) {
    final rows = data as List<dynamic>? ?? [];
    return rows.whereType<Map<String, dynamic>>().map(UserProfile.fromJson).toList();
  }
}
