import 'dart:async';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final room = await _repo.openBookingRoom(widget.bookingId);
      final roomId = room['id']?.toString();
      if (roomId == null || roomId.isEmpty) throw StateError('Không tìm thấy phòng chat.');
      final messages = await _repo.messages(roomId);
      final myId = await _repo.currentUserId();
      if (!mounted) return;
      setState(() {
        _roomId = roomId;
        _myUserId = myId;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
      _markSeen();
      await _connectRealtime(roomId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _connectRealtime(String roomId) async {
    _disposeConnection();
    try {
      final connection = await _repo.connect(roomId);
      if (!mounted) {
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
          if (!mounted) return;
          setState(() => _online = online);
          // After (re)connecting, pull history so nothing sent while offline is missed.
          if (online) {
            try {
              final latest = await _repo.messages(roomId);
              if (mounted) {
                for (final m in latest) {
                  _addMessage(m, scroll: false);
                }
                _scrollToBottom();
              }
            } catch (_) {}
          }
        }));
    } catch (_) {
      // Realtime is best-effort; sending/receiving by REST still works.
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
    ChatUnread.instance.markSeen(
      roomId, DateTime.tryParse(_messages.last['created_at']?.toString() ?? ''));
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
        SnackBar(content: Text('Không gửi được tin nhắn: $e')),
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
            const Text('Chat dịch vụ'),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 9, color: _online ? Colors.greenAccent : Colors.white54),
          ],
        ),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 44),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: () {
                          setState(() { _loading = true; _error = null; });
                          _initialize();
                        }, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFEAF7F7),
                      padding: const EdgeInsets.all(12),
                      child: const Text(
                        'Trao đổi trực tiếp về booking này. Không chia sẻ mật khẩu hoặc mã xác thực.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF23656A)),
                      ),
                    ),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện.'))
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
                      const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Đang nhập...', style: TextStyle(fontSize: 12, color: Colors.black54)),
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
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _sending ? null : _send,
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
    );
  }
}
