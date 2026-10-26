import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'chat_repository.dart';

/// App-wide inbox state: the list of conversations plus "unread" markers.
///
/// "Read" is remembered on this device only (secure storage), so no database
/// column is needed. A conversation is unread when its latest message was sent
/// by the other person and is newer than the last time this device opened it.
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
  bool _starting = false;

  List<ChatRoomSummary> get rooms => _rooms;
  String get userId => _userId;
  int get count => _rooms.where(isUnread).length;

  String get _key => 'coolcare_chat_seen_$_userId';

  bool isUnread(ChatRoomSummary room) {
    final at = room.lastAt;
    if (at == null || room.lastSenderId == null) return false;
    if (room.lastSenderId == _userId) return false;
    final seen = DateTime.tryParse(_seen[room.id] ?? '');
    return seen == null || at.isAfter(seen);
  }

  /// Safe to call repeatedly (e.g. from several screens); restarts on account change.
  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    try {
      final userId = await _repo.currentUserId();
      if (userId.isEmpty) return stop();
      if (userId == _userId && _socket != null) return refresh();
      stop();
      _userId = userId;
      try {
        final raw = await _storage.read(key: _key);
        final decoded = raw == null ? null : jsonDecode(raw);
        _seen = decoded is Map
            ? decoded.map((k, v) => MapEntry(k.toString(), v.toString()))
            : {};
      } catch (_) {
        _seen = {};
      }
      await refresh();
      try {
        final socket = await _repo.openUserSocket();
        socket
          ..on('chat:notify', (_) => refresh())
          ..onConnect((_) => refresh());
        _socket = socket;
      } catch (_) {}
      // Safety net if the socket is blocked or drops silently.
      _poll = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
    } finally {
      _starting = false;
    }
  }

  void stop() {
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

  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    try {
      _rooms = await _repo.rooms();
      notifyListeners();
    } catch (_) {
      // Keep the last known list on a brief network failure.
    }
  }

  /// Call when the user has seen messages up to [at] in [roomId].
  Future<void> markSeen(String roomId, DateTime? at) async {
    if (_userId.isEmpty || at == null) return;
    final current = DateTime.tryParse(_seen[roomId] ?? '');
    final value = at.toUtc();
    if (current != null && !value.isAfter(current)) return;
    _seen[roomId] = value.toIso8601String();
    notifyListeners();
    try {
      await _storage.write(key: _key, value: jsonEncode(_seen));
    } catch (_) {}
  }
}
