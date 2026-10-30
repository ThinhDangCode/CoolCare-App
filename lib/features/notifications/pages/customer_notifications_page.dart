import 'package:flutter/material.dart';

import '../../../app/localization/notification_text.dart';

import '../models/customer_notification.dart';
import '../repositories/customer_notifications_repository.dart';
import '../widgets/notification_detail_dialog.dart';

class CustomerNotificationsPage extends StatefulWidget {
  const CustomerNotificationsPage({super.key, this.repository});

  final CustomerNotificationsRepository? repository;

  @override
  State<CustomerNotificationsPage> createState() =>
      _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState extends State<CustomerNotificationsPage> {
  static const _ink = Color(0xFF193943);
  static const _muted = Color(0xFF657F8A);
  static const _teal = Color(0xFF087F92);

  late final CustomerNotificationsRepository _repository;
  final ScrollController _scrollController = ScrollController();
  final List<CustomerNotification> _items = [];
  bool _unreadOnly = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;
  int _page = 0;
  int _totalPages = 1;
  int _unreadCount = 0;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CustomerNotificationsRepository();
    _scrollController.addListener(_handleScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 280) _loadMore();
  }

  Future<void> _load({bool reset = false}) async {
    final generation = ++_requestGeneration;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _page = 0;
        _totalPages = 1;
      });
    }
    try {
      final result = await _repository.list(page: 1, unreadOnly: _unreadOnly);
      if (!mounted || generation != _requestGeneration) return;
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
      if (!mounted || generation != _requestGeneration) return;
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
      final result = await _repository.list(
        page: _page + 1,
        unreadOnly: _unreadOnly,
      );
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

  Future<void> _selectFilter(bool unreadOnly) async {
    if (_unreadOnly == unreadOnly) return;
    setState(() => _unreadOnly = unreadOnly);
    await _load(reset: true);
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
      await _load(reset: true);
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
            if (_unreadOnly) {
              _items.removeAt(index);
            } else {
              _items[index] = _items[index].copyWith(isRead: true);
            }
            _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30).toInt();
          });
        }
      } catch (error) {
        if (!mounted) return;
        _showError(error, () => _openNotification(item));
        return;
      }
    }

    if (!mounted) return;
    final iconStyle = _iconStyle(item.type);
    await showDialog<void>(
      context: context,
      builder: (_) => NotificationDetailDialog(
        title: localizedNotificationTitle(context, item.title),
        message: localizedNotificationMessage(context, item.message),
        bookingCode: item.bookingCode,
        timestamp: '${_dateGroup(item.createdAt)} · ${_time(item.createdAt)}',
        icon: iconStyle.$1,
        iconBackground: iconStyle.$2,
        iconColor: iconStyle.$3,
      ),
    );
  }

  void _showError(Object error, VoidCallback retry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to update notification: $error'),
        action: SnackBarAction(label: 'Retry', onPressed: retry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFDBE7EB)),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: !_unreadOnly,
                onTap: () => _selectFilter(false),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _unreadCount > 0 ? 'Unread ($_unreadCount)' : 'Unread',
                selected: _unreadOnly,
                onTap: () => _selectFilter(true),
              ),
            ],
          ),
          if (_unreadCount > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _markingAll ? null : _markAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: _teal,
                  padding: const EdgeInsets.only(top: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _markingAll ? 'Updating…' : 'Mark all as read',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeletons();
    if (_error != null) return _buildError();
    if (_items.isEmpty) return _buildEmpty();

    final children = <Widget>[];
    String? currentGroup;
    for (final item in _items) {
      final group = _dateGroup(item.createdAt);
      if (group != currentGroup) {
        children.add(_dateHeader(group));
        currentGroup = group;
      }
      children.add(_notificationTile(item));
    }
    if (_loadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator(color: _teal)),
        ),
      );
    }
    return RefreshIndicator(
      color: _teal,
      onRefresh: () => _load(reset: true),
      child: ListView(controller: _scrollController, children: children),
    );
  }

  Widget _buildSkeletons() => ListView.builder(
    itemCount: 5,
    itemBuilder: (_, _) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDBE7EB))),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(0.56),
                const SizedBox(height: 8),
                _skeletonLine(1),
                const SizedBox(height: 8),
                _skeletonLine(0.22),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _skeletonLine(double widthFactor) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Notifications',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An error occurred. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _load(reset: true),
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() {
    final allRead = _unreadOnly && _unreadCount == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allRead
                    ? Icons.check_rounded
                    : Icons.notifications_none_rounded,
                color: _teal,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              allRead ? 'All Caught Up' : 'No Notifications',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allRead
                  ? 'No unread notifications.'
                  : 'Booking and service notifications will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
    child: Text(
      title,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _notificationTile(CustomerNotification item) {
    final style = _iconStyle(item.type);
    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFEAF6F7),
      child: InkWell(
        onTap: () => _openNotification(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDBE7EB))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: style.$2,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.$1, size: 18, color: style.$3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedNotificationTitle(context, item.title),
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: item.isRead
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      localizedNotificationMessage(context, item.message),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (item.bookingCode != null &&
                        item.bookingCode!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.bookingCode!,
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: CircleAvatar(radius: 4, backgroundColor: _teal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconStyle(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING':
        return (
          Icons.check_rounded,
          const Color(0xFFE8F6ED),
          const Color(0xFF16A34A),
        );
      case 'CHAT':
      case 'MESSAGE':
        return (
          Icons.chat_bubble_outline_rounded,
          const Color(0xFFE6F2F4),
          _teal,
        );
      case 'QUOTATION':
        return (
          Icons.description_outlined,
          const Color(0xFFFDF3E6),
          const Color(0xFFEA8A00),
        );
      case 'PAYMENT':
        return (
          Icons.payments_outlined,
          const Color(0xFFE8F6ED),
          const Color(0xFF16A34A),
        );
      case 'COMPLAINT':
        return (
          Icons.report_gmailerrorred_outlined,
          const Color(0xFFFCE9E9),
          const Color(0xFFDC2626),
        );
      case 'VERIFICATION':
        return (
          Icons.verified_user_outlined,
          const Color(0xFFEBF3FE),
          const Color(0xFF3B82F6),
        );
      case 'RECONCILIATION':
        return (
          Icons.receipt_long_outlined,
          const Color(0xFFFDF3E6),
          const Color(0xFFEA8A00),
        );
      default:
        return (
          Icons.notifications_none_rounded,
          const Color(0xFFE6F2F4),
          _teal,
        );
    }
  }

  String _dateGroup(DateTime? date) {
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _time(DateTime? date) {
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFEAF6F7) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: const Color(0xFFDBE7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF087F92) : const Color(0xFF657F8A),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}
