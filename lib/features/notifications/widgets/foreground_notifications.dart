import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../app/localization/notification_text.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../models/customer_notification.dart';
import '../repositories/customer_notifications_repository.dart';

class ForegroundNotifications extends StatefulWidget {
  const ForegroundNotifications({
    required this.userId,
    required this.child,
    this.repository,
    super.key,
  });

  final String? userId;
  final Widget child;
  final CustomerNotificationsRepository? repository;

  static int unreadCountOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NotificationScope>()?.count ??
      0;

  static Future<void> refresh(BuildContext context) async {
    await context
        .getInheritedWidgetOfExactType<_NotificationScope>()
        ?.refresh();
  }

  @override
  State<ForegroundNotifications> createState() =>
      _ForegroundNotificationsState();
}

class _ForegroundNotificationsState extends State<ForegroundNotifications>
    with WidgetsBindingObserver {
  static const _refreshInterval = Duration(seconds: 5);
  static const _popupDuration = Duration(seconds: 4);

  late final _repository =
      widget.repository ?? CustomerNotificationsRepository();
  final _pending = Queue<CustomerNotification>();
  final _latestIds = <String>{};
  Timer? _refreshTimer;
  Timer? _dismissTimer;
  CustomerNotification? _visible;
  DateTime? _latestCreatedAt;
  bool _hasSnapshot = false;
  bool _refreshing = false;
  late bool _foreground;
  int _generation = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    _restartPolling();
  }

  @override
  void didUpdateWidget(covariant ForegroundNotifications oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId == widget.userId) return;
    _generation++;
    _refreshing = false;
    _hasSnapshot = false;
    _latestCreatedAt = null;
    _latestIds.clear();
    _pending.clear();
    _visible = null;
    _unreadCount = 0;
    _dismissTimer?.cancel();
    _restartPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _restartPolling();
    if (_visible != null || (_foreground && _pending.isNotEmpty)) {
      _advancePopup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _restartPolling() {
    _refreshTimer?.cancel();
    if (!_foreground || widget.userId == null) return;
    unawaited(_refresh());
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(_refresh()),
    );
  }

  bool _canApply(int generation) =>
      mounted && _foreground && generation == _generation;

  Future<void> _refresh() async {
    if (_refreshing || !_foreground || widget.userId == null) return;
    final generation = _generation;
    _refreshing = true;
    try {
      final first = await _repository.list();
      if (!_canApply(generation)) return;
      final newest = first.items
          .map((item) => item.createdAt)
          .nonNulls
          .firstOrNull;
      // Keep the existing inbox as the baseline. Subsequent polls collect all
      // arrivals up to the previous newest timestamp, including ties.
      final cutoff = _hasSnapshot ? _latestCreatedAt : newest;
      final recent = <String, CustomerNotification>{};
      var page = first;
      var pageNumber = 1;
      while (true) {
        for (final item in page.items) {
          final createdAt = item.createdAt;
          if (item.id.isNotEmpty &&
              createdAt != null &&
              (cutoff == null || !createdAt.isBefore(cutoff))) {
            recent.putIfAbsent(item.id, () => item);
          }
        }
        final oldest = page.items.lastOrNull?.createdAt;
        if (oldest == null ||
            pageNumber >= page.totalPages ||
            (cutoff != null && oldest.isBefore(cutoff))) {
          break;
        }
        page = await _repository.list(page: ++pageNumber);
        if (!_canApply(generation)) return;
      }

      if (_hasSnapshot) {
        _pending.addAll(
          recent.values.toList().reversed.where((item) {
            return !item.isRead &&
                (item.createdAt != cutoff || !_latestIds.contains(item.id));
          }),
        );
      }
      if (newest != null &&
          (_latestCreatedAt == null || !newest.isBefore(_latestCreatedAt!))) {
        if (newest != _latestCreatedAt) _latestIds.clear();
        _latestCreatedAt = newest;
        _latestIds.addAll(
          recent.values
              .where((item) => item.createdAt == newest)
              .map((item) => item.id),
        );
      }
      _hasSnapshot = true;
      if (_unreadCount != first.unreadCount) {
        setState(() => _unreadCount = first.unreadCount);
      }
      if (_visible == null && _pending.isNotEmpty) _advancePopup();
    } catch (_) {
      // Keep the last successful snapshot and retry on the next refresh.
    } finally {
      if (generation == _generation) _refreshing = false;
    }
  }

  void _advancePopup() {
    _dismissTimer?.cancel();
    setState(() {
      _visible = _foreground && _pending.isNotEmpty
          ? _pending.removeFirst()
          : null;
    });
    if (_visible != null) _dismissTimer = Timer(_popupDuration, _advancePopup);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return _NotificationScope(
      count: _unreadCount,
      refresh: _refresh,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (visible != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _NotificationPopup(
                      item: visible,
                      onDismiss: _advancePopup,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationScope extends InheritedWidget {
  const _NotificationScope({
    required this.count,
    required this.refresh,
    required super.child,
  });

  final int count;
  final Future<void> Function() refresh;

  @override
  bool updateShouldNotify(_NotificationScope oldWidget) =>
      oldWidget.count != count;
}

class _NotificationPopup extends StatelessWidget {
  const _NotificationPopup({required this.item, required this.onDismiss});

  final CustomerNotification item;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = localizedNotificationMessage(context, item.message);
    return Semantics(
      liveRegion: true,
      child: Material(
        color: context.appElevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appBorder),
        ),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedNotificationTitle(context, item.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appSubtleText),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
