import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'chat_repository.dart';

/// App-wide inbox state and locally stored unread markers.
class ChatUnread extends ChangeNotifier {
  ChatUnread._();

  static final ChatUnread instance = ChatUnread._();

  final ChatRepository _repo = ChatRepository();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<ChatRoomSummary> _rooms = const [];
  Map<String, String> _seen = {};
  String _userId = '';
  io.Socket? _socket;
  Timer? _poll;
  Future<void>? _startFuture;
  Future<void>? _refreshFuture;
  int _generation = 0;

  List<ChatRoomSummary> get rooms => _rooms;
  String get userId => _userId;
  int get count => _rooms.where(isUnread).length;
  String get _key => 'coolcare_chat_seen_$_userId';

  bool isUnread(ChatRoomSummary room) {
    final at = room.lastAt;
    if (at == null ||
        room.lastSenderId == null ||
        room.lastSenderId == _userId) {
      return false;
    }
    final seen = DateTime.tryParse(_seen[room.id] ?? '');
    return seen == null || at.isAfter(seen);
  }

  Future<void> start() {
    final existing = _startFuture;
    if (existing != null) return existing;
    final future = _start();
    _startFuture = future;
    unawaited(future.then((_) {
      if (identical(_startFuture, future)) _startFuture = null;
    }, onError: (Object error, StackTrace stack) {
      if (identical(_startFuture, future)) _startFuture = null;
    }));
    return future;
  }

  Future<void> _start() async {
    debugPrint('[CHAT UNREAD] START');
    try {
      final userId = await _repo.currentUserId();
      if (userId.isEmpty) {
        stop();
        return;
      }
      if (userId == _userId) {
        await refresh();
        debugPrint('[CHAT UNREAD] START DONE');
        return;
      }

      stop();
      _userId = userId;
      final generation = _generation;
      try {
        final raw = await _storage.read(key: _key)
            .timeout(const Duration(seconds: 5));
        if (generation != _generation) return;
        final decoded = raw == null ? null : jsonDecode(raw);
        _seen = decoded is Map
            ? decoded.map((key, value) =>
                MapEntry(key.toString(), value.toString()))
            : <String, String>{};
      } catch (e) {
        debugPrint('[CHAT UNREAD] Read markers unavailable: $e');
        _seen = {};
      }
      if (generation != _generation) return;

      await refresh();
      if (generation != _generation) return;
      debugPrint('[CHAT UNREAD] Initial rooms ready: ${_rooms.length}');

      // Realtime must never delay the inbox's first render.
      unawaited(_connectSocket(generation));
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 60), (_) {
        unawaited(refresh().catchError((Object e) {
          debugPrint('[CHAT UNREAD] Poll failed: $e');
        }));
      });
      debugPrint('[CHAT UNREAD] START DONE');
    } catch (e, stack) {
      debugPrint('[CHAT UNREAD] START ERROR: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _connectSocket(int generation) async {
    try {
      final socket = await _repo.openUserSocket()
          .timeout(const Duration(seconds: 8));
      if (generation != _generation) {
        socket.dispose();
        return;
      }
      _socket = socket;
      socket.on('chat:notify', (_) {
        if (generation != _generation) return;
        unawaited(refresh().catchError((Object e) {
          debugPrint('[CHAT SOCKET] Notify refresh failed: $e');
        }));
      });
      socket.onConnect((_) {
        if (generation != _generation) return;
        debugPrint('[CHAT SOCKET] Inbox connected');
        unawaited(refresh().catchError((Object e) {
          debugPrint('[CHAT SOCKET] Connect refresh failed: $e');
        }));
      });
      socket.onDisconnect((reason) {
        debugPrint('[CHAT SOCKET] Inbox disconnected: $reason');
      });
      socket.onConnectError((error) {
        if (generation != _generation) return;
        debugPrint('[CHAT SOCKET] Inbox connection error: $error');
        if (error.toString().contains('SESSION_REPLACED')) {
          debugPrint('[CHAT SOCKET] Session replaced; stopping realtime');
          socket.disconnect();
        }
      });
      socket.connect();
      debugPrint('[CHAT SOCKET] Connection initiated');
    } catch (e, stack) {
      debugPrint('[CHAT SOCKET] Inbox unavailable: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void stop() {
    _generation++;
    _poll?.cancel();
    _poll = null;
    _socket?.dispose();
    _socket = null;
    _userId = '';
    _seen = {};
    if (_rooms.isNotEmpty) {
      _rooms = const [];
      notifyListeners();
    }
  }

  Future<void> refresh() {
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final future = _refresh();
    _refreshFuture = future;
    unawaited(future.then((_) {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    }, onError: (Object error, StackTrace stack) {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    }));
    return future;
  }

  Future<void> _refresh() async {
    if (_userId.isEmpty) {
      debugPrint('[CHAT UNREAD] Refresh skipped: no user');
      return;
    }
    final generation = _generation;
    try {
      debugPrint('[CHAT UNREAD] Loading rooms...');
      final rooms = await _repo.rooms().timeout(const Duration(seconds: 10));
      debugPrint('[CHAT UNREAD] API returned ${rooms.length} rooms');
      if (generation != _generation) return;
      _rooms = rooms;
      notifyListeners();
      debugPrint('[CHAT UNREAD] Rooms updated successfully');
    } catch (e, stack) {
      debugPrint('[CHAT UNREAD] Refresh failed: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  Future<void> markSeen(String roomId, DateTime? at) async {
    if (_userId.isEmpty || at == null) return;
    final storageKey = _key;
    final current = DateTime.tryParse(_seen[roomId] ?? '');
    final value = at.toUtc();
    if (current != null && !value.isAfter(current)) return;
    _seen[roomId] = value.toIso8601String();
    notifyListeners();
    try {
      await _storage.write(key: storageKey, value: jsonEncode(_seen))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[CHAT UNREAD] Persist seen failed: $e');
    }
  }
}
