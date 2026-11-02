import 'dart:async';

import 'package:flutter/material.dart';
import '../../app/localization/app_strings.dart';
import 'chat_repository.dart';
import 'chat_unread.dart';

class BookingChatPage extends StatefulWidget {
  const BookingChatPage({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingChatPage> createState() => _BookingChatPageState();
}

class _BookingChatPageState extends State<BookingChatPage> {
  static const _teal = Color(0xFF078B96);
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _roomId;
  String _myUserId = '';
  ChatConnection? _connection;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _typingStop;
  bool _iAmTyping = false;
  bool _otherTyping = false;
  bool _online = false;
  String? _error;
  bool _loading = true;
  bool _sending = false;
  int _initGeneration = 0;
  bool _everConnected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }


  Future<void> _initialize() async {
    final generation = ++_initGeneration;
    _disposeConnection();
    _everConnected = false;
    _roomId = null;
    _online = false;
    _otherTyping = false;
    _messages = [];
    _error = null;
    _loading = true;

    try {
      debugPrint('[CHAT] Initialize booking: ${widget.bookingId}');

      // The inbox already knows the room ID. Avoid a redundant POST when possible.
      String? roomId;
      for (final room in ChatUnread.instance.rooms) {
        if (room.bookingId == widget.bookingId && room.id.isNotEmpty) {
          roomId = room.id;
          break;
        }
      }
      if (roomId == null) {
        debugPrint('[CHAT] Room not cached; requesting room from REST');
        final room = await _repo.openBookingRoom(widget.bookingId)
            .timeout(const Duration(seconds: 10));
        roomId = room['id']?.toString();
      }
      if (roomId == null || roomId.isEmpty) {
        throw StateError(context.tr('chatRoomMissing'));
      }
      if (!mounted || generation != _initGeneration) return;
      final resolvedRoomId = roomId;
      setState(() => _roomId = resolvedRoomId);
      debugPrint('[CHAT] Room ready: $resolvedRoomId');

      // The user ID and history are independent: load them in parallel.
      final results = await Future.wait<Object>([
        _repo.messages(resolvedRoomId).timeout(const Duration(seconds: 12)),
        _repo.currentUserId().timeout(const Duration(seconds: 8)),
      ]);
      if (!mounted || generation != _initGeneration) return;
      final messages = results[0] as List<Map<String, dynamic>>;
      final myId = results[1] as String;
      messages.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));
      setState(() {
        _myUserId = myId;
        _messages = messages;
        _loading = false;
        _error = null;
      });
      debugPrint('[CHAT] History ready: ${messages.length} messages');
      _scrollToBottom();
      _markSeen();

      // Best effort only. Socket.IO never blocks rendering or REST history.
      unawaited(_connectRealtime(resolvedRoomId, generation));
    } catch (error, stackTrace) {
      debugPrint('[CHAT] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || generation != _initGeneration) return;
      setState(() {
        _loading = false;
        _error = error is TimeoutException
            ? 'Tải cuộc trò chuyện quá thời gian. Vui lòng thử lại.'
            : error.toString().replaceFirst('Exception: ', '');
      });
    }
  }


  Future<void> _connectRealtime(String roomId, int generation) async {
    _disposeConnection();
    try {
      final connection = await _repo.connect(roomId)
          .timeout(const Duration(seconds: 8));
      if (!mounted || generation != _initGeneration) {
        connection.dispose();
        return;
      }
      _connection = connection;
      _subs
        ..add(connection.messages.listen(_addMessage))
        ..add(connection.typing.listen((typing) {
          if (mounted) setState(() => _otherTyping = typing);
        }))
        ..add(connection.connected.listen((online) async {
          if (!mounted || generation != _initGeneration) return;
          setState(() => _online = online);
          // After (re)connecting, pull history so nothing sent while offline is missed.
          if (online && _everConnected) {
            try {
              final latest = await _repo.messages(roomId)
                  .timeout(const Duration(seconds: 12));
              if (mounted && generation == _initGeneration) {
                for (final m in latest) {
                  _addMessage(m, scroll: false);
                }
                _scrollToBottom();
              }
            } catch (e) {
              debugPrint('[CHAT] Reconnect sync failed: $e');
            }
          }
          if (online) _everConnected = true;
        }));
    } catch (error) {
      debugPrint('[CHAT] Realtime unavailable (REST remains usable): $error');
    }
  }

  void _addMessage(Map<String, dynamic> message, {bool scroll = true}) {
    final id = message['id']?.toString();
    if (id == null || _messages.any((m) => m['id']?.toString() == id)) return;
    if (!mounted) return;
    setState(() {
      _messages = [..._messages, message]
        ..sort((a, b) => (a['created_at']?.toString() ?? '')
            .compareTo(b['created_at']?.toString() ?? ''));
    });
    if (scroll) _scrollToBottom();
    _markSeen();
  }

  void _markSeen() {
    final roomId = _roomId;
    if (roomId == null || _messages.isEmpty) return;
    unawaited(ChatUnread.instance.markSeen(
        roomId, DateTime.tryParse(_messages.last['created_at']?.toString() ?? '')));
  }

  void _onTextChanged(String value) {
    final connection = _connection;
    if (connection == null) return;
    if (!_iAmTyping && value.isNotEmpty) {
      _iAmTyping = true;
      connection.setTyping(true);
    }
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingStop?.cancel();
    if (_iAmTyping) {
      _iAmTyping = false;
      _connection?.setTyping(false);
    }
  }

  void _disposeConnection() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _connection?.dispose();
    _connection = null;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final roomId = _roomId;
    if (text.isEmpty || roomId == null || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _repo.send(roomId, text);
      if (!mounted) return;
      _controller.clear();
      _stopTyping();
      _addMessage(message); // the realtime echo of the same id is ignored
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('chatSendFailed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _initGeneration++;
    _typingStop?.cancel();
    _disposeConnection();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('chatTitle')),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 9, color: _online ? Colors.greenAccent : Colors.white54),
          ],
        ),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 3),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() { _loading = true; _error = null; });
                      unawaited(_initialize());
                    },
                    child: Text(context.tr('tryAgain')),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  color: const Color(0xFFEAF7F7),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr('chatNotice'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF23656A)),
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(child: Text(_loading ? 'Đang tải tin nhắn...' : context.tr('chatEmptyRoom')))
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final content = message['content']?.toString() ?? '';
                      final time = DateTime.tryParse(message['created_at']?.toString() ?? '')?.toLocal();
                      final mine = message['sender_id']?.toString() == _myUserId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xFFD5F0F2) : const Color(0xFFF0F2F4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content),
                              if (time != null) ...[
                                const SizedBox(height: 4),
                                Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black54)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_otherTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(context.tr('chatTyping'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onChanged: _onTextChanged,
                            onSubmitted: (_) { if (!_loading && _error == null) _send(); },
                            decoration: InputDecoration(
                              hintText: context.tr('chatMessageHint'),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: (_sending || _loading || _error != null || _roomId == null) ? null : _send,
                          style: IconButton.styleFrom(backgroundColor: _teal),
                          icon: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
