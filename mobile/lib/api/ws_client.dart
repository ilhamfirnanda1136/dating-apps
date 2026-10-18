import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat.dart';
import '../models/user_profile.dart';
import 'api_config.dart';

typedef OnMessageCallback = void Function(String matchId, ChatMessage message);
typedef OnMatchCallback = void Function(String matchId, UserProfile user);
typedef OnTypingCallback = void Function(String matchId, String userId, bool isTyping);
typedef OnMessagesReadCallback = void Function(String matchId, String readerId);
typedef OnConnectionChangeCallback = void Function(bool isConnected);

/// Klien WebSocket 2 arah untuk chat dan notifikasi real-time.
class WsClient {
  WsClient();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _token;
  bool _isConnected = false;
  bool _disposed = false;

  bool get isConnected => _isConnected;

  OnMessageCallback? onMessage;
  OnMatchCallback? onMatch;
  OnTypingCallback? onTyping;
  OnMessagesReadCallback? onMessagesRead;
  OnConnectionChangeCallback? onConnectionChange;

  /// Membuka koneksi WebSocket dengan token autentikasi JWT.
  void connect(String token) {
    if (_disposed) return;
    _token = token;
    _reconnectTimer?.cancel();

    try {
      final wsUri = Uri.parse('${ApiConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(wsUri);

      _subscription = _channel!.stream.listen(
        _handleIncoming,
        onDone: _handleDone,
        onError: _handleError,
      );

      _isConnected = true;
      onConnectionChange?.call(true);

      _startPing();
    } catch (e) {
      debugPrint('[WsClient] Gagal konek: $e');
      _scheduleReconnect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null) {
        send({'type': 'ping'});
      }
    });
  }

  void _handleIncoming(dynamic raw) {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final map = jsonDecode(text) as Map<String, dynamic>;
      final type = map['type'] as String?;

      switch (type) {
        case 'new_message':
          final data = map['data'] as Map<String, dynamic>? ?? {};
          final matchId = data['match_id'] as String? ?? '';
          final msgJson = data['message'] as Map<String, dynamic>? ?? {};
          if (matchId.isNotEmpty && msgJson.isNotEmpty) {
            final chatMessage = ChatMessage.fromJson(
              msgJson,
              fallbackIsMe: msgJson['is_me'] == true,
            );
            onMessage?.call(matchId, chatMessage);
          }
          break;

        case 'new_match':
          final data = map['data'] as Map<String, dynamic>? ?? {};
          final matchId = data['match_id'] as String? ?? '';
          final userJson = data['user'] as Map<String, dynamic>? ?? {};
          if (matchId.isNotEmpty && userJson.isNotEmpty) {
            final user = UserProfile.fromJson(userJson);
            onMatch?.call(matchId, user);
          }
          break;

        case 'typing':
          final data = map['data'] as Map<String, dynamic>? ?? {};
          final matchId = data['match_id'] as String? ?? '';
          final userId = data['user_id'] as String? ?? '';
          final isTyping = data['is_typing'] == true;
          if (matchId.isNotEmpty) {
            onTyping?.call(matchId, userId, isTyping);
          }
          break;

        case 'messages_read':
          final data = map['data'] as Map<String, dynamic>? ?? {};
          final matchId = data['match_id'] as String? ?? '';
          final readerId = data['reader_id'] as String? ?? '';
          if (matchId.isNotEmpty) {
            onMessagesRead?.call(matchId, readerId);
          }
          break;

        case 'pong':
          // Heartbeat diterima
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[WsClient] Error parsing incoming: $e');
    }
  }

  void _handleDone() {
    _isConnected = false;
    onConnectionChange?.call(false);
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    debugPrint('[WsClient] Error: $error');
    _isConnected = false;
    onConnectionChange?.call(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _token == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (_token != null && !_isConnected) {
        connect(_token!);
      }
    });
  }

  /// Mengirim payload JSON ke server WebSocket.
  void send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('[WsClient] Gagal kirim payload: $e');
      }
    }
  }

  /// Mengirim pesan chat melalui WebSocket 2 arah.
  void sendMessage({
    required String matchId,
    required String content,
    String? mediaUrl,
    String? replyToId,
  }) {
    final payload = <String, dynamic>{
      'type': 'send_message',
      'match_id': matchId,
      'content': content,
    };
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      payload['media_url'] = mediaUrl;
    }
    if (replyToId != null && replyToId.isNotEmpty) {
      payload['reply_to_id'] = replyToId;
    }
    send(payload);
  }

  /// Mengirim status sedang mengetik.
  void sendTyping({required String matchId, required bool isTyping}) {
    send({
      'type': 'typing',
      'match_id': matchId,
      'is_typing': isTyping,
    });
  }

  /// Mengirim sinyal bahwa pesan telah dibaca.
  void sendMarkRead(String matchId) {
    send({
      'type': 'mark_read',
      'match_id': matchId,
    });
  }

  /// Menutup koneksi.
  void disconnect() {
    _token = null;
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    onConnectionChange?.call(false);
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
