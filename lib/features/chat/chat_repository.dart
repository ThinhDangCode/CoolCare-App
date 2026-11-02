import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/network/api_client.dart';
import '../auth/services/secure_session_store.dart';

class ChatRepository {
  ChatRepository({ApiClient? api, SecureSessionStore? sessions})
      : _api = api ?? ApiClient.fromEnvironment(),
        _sessions = sessions ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _sessions;

  Future<String> _token() async {
    final session = await _sessions.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Vui lòng đăng nhập để sử dụng chat.');
    }
    return session.token;
  }

  Future<String> currentUserId() async {
    final session = await _sessions.read();
    return session?.user.id ?? '';
  }

  Future<List<ChatRoomSummary>> rooms() async {
    final response = await _api.get('/chat/rooms', bearerToken: await _token());
    if (response is! Map || response['data'] is! List) {
      throw const FormatException('Dữ liệu hội thoại không hợp lệ.');
    }
    return (response['data'] as List)
        .whereType<Map>()
        .map((item) => ChatRoomSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Caller registers listeners before calling socket.connect().
  Future<io.Socket> openUserSocket() async {
    final origin = await _api.resolveOrigin();
    final token = await _token();
    return io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .build(),
    );
  }

  Future<Map<String, dynamic>> openBookingRoom(String bookingId) async {
    final response = await _api.post(
      '/chat/bookings/$bookingId/room',
      bearerToken: await _token(),
      body: const {},
    );
    if (response['data'] is! Map) {
      throw const FormatException('Dữ liệu phòng chat không hợp lệ.');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> messages(String roomId) async {
    final response = await _api.get(
      '/chat/rooms/$roomId/messages',
      bearerToken: await _token(),
    );
    if (response is! Map || response['data'] is! List) {
      throw const FormatException('Dữ liệu tin nhắn không hợp lệ.');
    }
    return (response['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> send(String roomId, String content) async {
    final response = await _api.post(
      '/chat/rooms/$roomId/messages',
      bearerToken: await _token(),
      body: {'content': content},
    );
    if (response['data'] is! Map) {
      throw const FormatException('Không gửi được tin nhắn.');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<ChatConnection> connect(String roomId) async {
    final connection = ChatConnection._(
      roomId: roomId,
      origin: await _api.resolveOrigin(),
      token: await _token(),
      refreshToken: _token,
    );
    connection._open();
    return connection;
  }
}

class ChatConnection {
  ChatConnection._({
    required this.roomId,
    required String origin,
    required String token,
    required Future<String> Function() refreshToken,
  }) : _refreshToken = refreshToken {
    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .build(),
    );
  }

  final String roomId;
  final Future<String> Function() _refreshToken;
  late final io.Socket _socket;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _typing = StreamController<bool>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  bool _disposed = false;

  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<bool> get typing => _typing.stream;
  Stream<bool> get connected => _connected.stream;

  bool _sessionReplaced(dynamic error) =>
      error.toString().contains('SESSION_REPLACED');

  void _open() {
    _socket
      ..onConnect((_) {
        if (_disposed) return;
        _socket.emitWithAck('chat:join', {'roomId': roomId}, ack: (data) {
          if (_disposed) return;
          final ok = data is Map && data['ok'] == true;
          _connected.add(ok);
        });
      })
      ..onDisconnect((_) {
        if (!_disposed) _connected.add(false);
      })
      ..onConnectError((error) async {
        if (_disposed) return;
        debugPrint('[CHAT SOCKET] Room connection error: $error');
        if (_sessionReplaced(error)) {
          // A revoked session must not reconnect indefinitely.
          _socket.disconnect();
          _connected.add(false);
          return;
        }
        try {
          final token = await _refreshToken();
          if (!_disposed) _socket.auth = {'token': token};
        } catch (e) {
          debugPrint('[CHAT SOCKET] Token reload failed: $e');
        }
      })
      ..on('chat:message', (data) {
        if (_disposed || data is! Map) return;
        _messages.add(Map<String, dynamic>.from(data));
      })
      ..on('chat:typing', (data) {
        if (_disposed || data is! Map) return;
        _typing.add(data['typing'] == true);
      })
      ..connect();
  }

  void setTyping(bool typing) {
    if (_socket.connected) {
      _socket.emit('chat:typing', {'roomId': roomId, 'typing': typing});
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _socket
      ..off('chat:message')
      ..off('chat:typing')
      ..dispose();
    _messages.close();
    _typing.close();
    _connected.close();
  }
}

class ChatRoomSummary {
  const ChatRoomSummary({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.otherName,
    this.serviceNames = '',
    this.scheduledAt,
    this.lastSenderId,
    this.lastContent,
    this.lastAt,
  });

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'] is Map
        ? Map<String, dynamic>.from(json['last_message'] as Map)
        : null;
    return ChatRoomSummary(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      bookingCode: json['booking_code']?.toString() ?? '',
      otherName: json['other_name']?.toString() ?? '',
      serviceNames: json['service_names']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '')?.toLocal(),
      lastSenderId: last?['sender_id']?.toString(),
      lastContent: last?['content']?.toString(),
      lastAt: DateTime.tryParse(last?['created_at']?.toString() ?? '')?.toUtc(),
    );
  }

  final String id;
  final String bookingId;
  final String bookingCode;
  final String otherName;
  final String serviceNames;
  final DateTime? scheduledAt;
  final String? lastSenderId;
  final String? lastContent;
  final DateTime? lastAt;
}
