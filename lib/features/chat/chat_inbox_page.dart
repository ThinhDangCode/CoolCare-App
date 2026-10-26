import 'package:flutter/material.dart';

import 'booking_chat_page.dart';
import 'chat_repository.dart';
import 'chat_unread.dart';

/// List of the signed-in user's conversations (one per booking).
/// Use [embedded] inside a tab that already has its own Scaffold.
class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  static const _teal = Color(0xFF078B96);
  final _unread = ChatUnread.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _unread.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    _unread.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await _unread.start();
    await _unread.refresh();
    if (mounted) setState(() => _loading = false);
  }

  String _time(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    final now = DateTime.now();
    final hm = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (local.year == now.year && local.month == now.month && local.day == now.day) return hm;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  Future<void> _open(ChatRoomSummary room) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingChatPage(bookingId: room.bookingId),
    ));
    _unread.refresh();
  }

  Widget _body() {
    if (_loading && _unread.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final rooms = _unread.rooms;
    if (rooms.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.forum_outlined, size: 44, color: Colors.black38),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Chưa có cuộc trò chuyện nào. Chat sẽ xuất hiện khi booking đã có kỹ thuật viên nhận việc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final unread = _unread.isUnread(room);
        // One row per order: identify it by code + service + date, then the other person.
        final code = room.bookingCode.isEmpty ? '' : '#${room.bookingCode}';
        final service = room.serviceNames.isEmpty ? 'Đơn dịch vụ' : room.serviceNames;
        final date = room.scheduledAt == null
            ? ''
            : ' · ${room.scheduledAt!.day.toString().padLeft(2, '0')}/${room.scheduledAt!.month.toString().padLeft(2, '0')}';
        final title = code.isEmpty ? service : '$code · $service';
        final mine = room.lastSenderId == _unread.userId;
        final who = mine ? 'Bạn: ' : (room.otherName.isEmpty ? '' : '${room.otherName}: ');
        return ListTile(
          onTap: () => _open(room),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEAF7F7),
            child: Icon(Icons.receipt_long_outlined, color: _teal, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
          ),
          subtitle: Text(
            room.lastContent == null
                ? '${room.otherName}$date · chưa có tin nhắn'
                : '$who${room.lastContent}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread ? Colors.black87 : Colors.black54,
              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_time(room.lastAt), style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 6),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                )
              else
                const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(onRefresh: _unread.refresh, child: _body());
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }
}
