import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../notifications/models/customer_notification.dart';
import '../../notifications/widgets/notification_detail_dialog.dart';
import '../repositories/technician_notifications_repository.dart';

class TechnicianNotificationsPage extends StatefulWidget {
  const TechnicianNotificationsPage({super.key, this.repository});

  final TechnicianNotificationsRepository? repository;

  @override
  State<TechnicianNotificationsPage> createState() =>
      _TechnicianNotificationsPageState();
}

class _TechnicianNotificationsPageState
    extends State<TechnicianNotificationsPage> {
  static const _ink = Color(0xFF193943);
  static const _muted = Color(0xFF657F8A);

  late final TechnicianNotificationsRepository _repository;
  Timer? _refreshTimer;
  final _items = <CustomerNotification>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;
  int _page = 0;
  int _totalPages = 1;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TechnicianNotificationsRepository();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshQuietly(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQuietly() async {
    if (_loading || _loadingMore || _markingAll || _error != null) return;
    try {
      final result = await _repository.list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
        _unreadCount = result.unreadCount;
      });
    } catch (_) {
      // Keep the visible list; pull-to-refresh and Retry remain available.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
        _unreadCount = result.unreadCount;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _totalPages || _error != null) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final result = await _repository.list(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
        _unreadCount = result.unreadCount;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = '$error';
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0 || _markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _repository.markAllRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
        _markingAll = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      _showError(error, _markAllRead);
    }
  }

  Future<void> _openNotification(CustomerNotification item) async {
    if (!item.isRead) {
      try {
        await _repository.markRead(item.id);
        if (!mounted) return;
        final index = _items.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          setState(() {
            _items[index] = _items[index].copyWith(isRead: true);
            _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30).toInt();
          });
        }
      } catch (error) {
        if (mounted) _showError(error, () => _openNotification(item));
        return;
      }
    }
    if (!mounted) return;
    final iconStyle = _iconStyle(item.type, item.title);
    await showDialog<void>(
      context: context,
      builder: (_) => NotificationDetailDialog(
        title: item.title,
        message: item.message,
        bookingCode: item.bookingCode,
        timestamp: _time(item.createdAt),
        icon: iconStyle.$1,
        iconBackground: iconStyle.$2,
        iconColor: iconStyle.$3,
      ),
    );
  }

  void _showError(Object error, Future<void> Function() retry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Không thể cập nhật thông báo. Vui lòng thử lại. ($error)',
        ),
        action: SnackBarAction(label: 'Thử lại', onPressed: retry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _unreadCount == 0 || _markingAll ? null : _markAllRead,
            child: _markingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load notifications.'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Text('No Notifications', style: TextStyle(color: _muted)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 260) _loadMore();
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _items.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _items[index];
                    final showDate =
                        index == 0 ||
                        !_sameDay(item.createdAt, _items[index - 1].createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                            child: Text(
                              _dateLabel(item.createdAt),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        _tile(item),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _tile(CustomerNotification item) {
    final style = _iconStyle(item.type, item.title);
    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFEAF6F7),
      child: InkWell(
        onTap: () => _openNotification(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDBE7EB))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: style.$2,
                child: Icon(style.$1, color: style.$3, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: item.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (item.bookingCode?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.bookingCode!,
                        style: const TextStyle(
                          color: CoolCareColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      _time(item.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                const Padding(
                  padding: EdgeInsets.only(top: 5, left: 8),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: CoolCareColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconStyle(String type, String title) {
    if (title == 'Bạn nhận được đánh giá mới') {
      return (
        Icons.star_outline_rounded,
        const Color(0xFFFFF1D8),
        const Color(0xFFB77A16),
      );
    }
    switch (type.toUpperCase()) {
      case 'BOOKING':
      case 'JOB_REQUEST':
        return (
          Icons.build_outlined,
          const Color(0xFFE7F3F6),
          const Color(0xFF27879A),
        );
      case 'MESSAGE':
        return (
          Icons.chat_bubble_outline,
          const Color(0xFFFFF1D8),
          const Color(0xFFB77A16),
        );
      case 'QUOTATION':
        return (
          Icons.request_quote_outlined,
          const Color(0xFFEDE8FF),
          const Color(0xFF6E59B8),
        );
      case 'PAYMENT':
        return (
          Icons.payments_outlined,
          const Color(0xFFE5F5EC),
          const Color(0xFF36845A),
        );
      case 'CERTIFICATION':
        return (
          Icons.verified_outlined,
          const Color(0xFFEDE8FF),
          const Color(0xFF6E59B8),
        );
      case 'COMPLETED':
        return (
          Icons.check_circle_outline,
          const Color(0xFFE5F5EC),
          const Color(0xFF36845A),
        );
      default:
        return (
          Icons.notifications_none_rounded,
          const Color(0xFFE7F3F6),
          const Color(0xFF27879A),
        );
    }
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'EARLIER';
    final now = DateTime.now();
    final date = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'TODAY';
    if (date == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;

  String _time(DateTime? value) {
    if (value == null) return '';
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
