import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../app/localization/service_text.dart';

import 'booking_chat_page.dart';
import 'chat_repository.dart';
import 'chat_unread.dart';

/// List of the signed-in user's conversations (one per booking).
/// Use [embedded] inside a tab that already has its own Scaffold.
class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  static const _teal = Color(0xFF078B96);

  final ChatUnread _unread = ChatUnread.instance;

  bool _loading = false;
  String? _error;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();

    _unread.addListener(_changed);

    // Hiển thị dữ liệu có sẵn ngay, sau đó đồng bộ ở nền.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _unread.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
  }

  /// Khởi tạo danh sách chat.
  ///
  /// ChatUnread.start() đã thực hiện refresh().
  /// Không gọi refresh() thêm lần nữa.
  ///
  /// Timeout đảm bảo màn hình không loading vô hạn.
  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = _unread.rooms.isEmpty;
      _error = null;
    });

    try {
      debugPrint('[CHAT INBOX] Starting...');

      await _unread.start().timeout(
        const Duration(seconds: 15),
      );
      // start() chỉ chuẩn bị dữ liệu REST; Socket.IO chạy độc lập.

      debugPrint(
        '[CHAT INBOX] Started. Rooms: ${_unread.rooms.length}',
      );
    } on TimeoutException {
      debugPrint('[CHAT INBOX] Start timeout');

      if (mounted) {
        _error = 'Tải danh sách chat quá thời gian. Vui lòng thử lại.';
      }
    } catch (e, stackTrace) {
      debugPrint('[CHAT INBOX] Start failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _error = 'Không thể tải danh sách chat. Vui lòng thử lại.';
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Làm mới danh sách chat.
  Future<void> _refresh() async {
    if (_refreshing) return;

    _refreshing = true;

    try {
      debugPrint('[CHAT INBOX] Refreshing...');

      await _unread.refresh().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _error = null;
      });

      debugPrint(
        '[CHAT INBOX] Refresh completed: ${_unread.rooms.length}',
      );
    } on TimeoutException {
      debugPrint('[CHAT INBOX] Refresh timeout');

      if (mounted) {
        setState(() {
          _error = 'Làm mới danh sách chat quá thời gian.';
        });
      }
    } catch (e) {
      debugPrint('[CHAT INBOX] Refresh failed: $e');

      if (mounted) {
        setState(() {
          _error = 'Không thể làm mới danh sách chat.';
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  String _time(DateTime? at) {
    if (at == null) return '';

    final local = at.toLocal();
    final now = DateTime.now();

    final hm =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return hm;
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  Future<void> _open(ChatRoomSummary room) async {
    debugPrint(
      '[CHAT INBOX] Opening booking: ${room.bookingId}',
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingChatPage(
          bookingId: room.bookingId,
        ),
      ),
    );

    if (!mounted) return;

    // Không chặn việc quay lại màn hình danh sách.
    unawaited(_refresh());
  }

  Widget _loadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: _teal,
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải cuộc trò chuyện...',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Không thể tải danh sách chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyWithStatus({required bool loading}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.forum_outlined, size: 48, color: _teal),
        const SizedBox(height: 16),
        Text(
          loading ? 'Đang đồng bộ danh sách cuộc trò chuyện...' : context.tr('chatEmptyInbox'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        if (loading) ...[
          const SizedBox(height: 16),
          const Center(child: SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _teal))),
        ],
      ],
    );
  }

  Widget _emptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.forum_outlined,
          size: 44,
          color: Colors.black38,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            context.tr('chatEmptyInbox'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final rooms = _unread.rooms;

    // Màn hình chat luôn dựng ngay, kể cả khi REST đang tải.
    // Không che toàn bộ giao diện bằng spinner.
    if (_loading && rooms.isEmpty) {
      return _emptyWithStatus(loading: true);
    }

    // Nếu tải lỗi và không có dữ liệu, hiện nút thử lại.
    if (_error != null && rooms.isEmpty) {
      return _errorView();
    }

    if (rooms.isEmpty) {
      return _emptyView();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final unread = _unread.isUnread(room);

        final code = room.bookingCode.isEmpty
            ? ''
            : '#${room.bookingCode}';

        final service = room.serviceNames.isEmpty
            ? context.tr('chatBooking')
            : localizedServiceNames(
          context,
          room.serviceNames,
        );

        final date = room.scheduledAt == null
            ? ''
            : ' · '
            '${room.scheduledAt!.day.toString().padLeft(2, '0')}/'
            '${room.scheduledAt!.month.toString().padLeft(2, '0')}';

        final title = code.isEmpty
            ? service
            : '$code · $service';

        final mine =
            room.lastSenderId == _unread.userId;

        final who = mine
            ? '${context.tr('chatYou')}: '
            : (room.otherName.isEmpty
            ? ''
            : '${room.otherName}: ');

        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListTile(
            onTap: () => _open(room),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF7F7),
              child: Icon(
                Icons.receipt_long_outlined,
                color: _teal,
                size: 20,
              ),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              room.lastContent == null
                  ? '${room.otherName}$date · '
                  '${context.tr('chatNoMessagesPreview')}'
                  : '$who${room.lastContent}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread
                    ? Colors.black87
                    : Colors.black54,
                fontWeight: unread
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _time(room.lastAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      color: _teal,
      onRefresh: _refresh,
      child: _body(),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('chatInboxTitle')),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_loading && _unread.rooms.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2, color: _teal),
          Expanded(child: content),
        ],
      ),
    );
  }
}
