
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../models/customer_ac_history.dart';
import '../repositories/ac_history_repository.dart';
import 'ac_history_format.dart';

// Service history of one air conditioner: services done, technician, date, status.
class AcServiceHistoryPage extends StatefulWidget {
  const AcServiceHistoryPage({
    super.key,
    required this.unit,
    this.repository,
  });

  final AcUnitGroup unit;
  final AcHistoryRepository? repository;

  @override
  State<AcServiceHistoryPage> createState() =>
      _AcServiceHistoryPageState();
}

class _AcServiceHistoryPageState extends State<AcServiceHistoryPage> {
  late final AcHistoryRepository _repo =
      widget.repository ?? AcHistoryRepository();

  final List<AcHistoryEntry> _items = [];

  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  Object? _moreError;

  bool get _vi =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _t(String vi, String en) => _vi ? vi : en;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _moreError = null;
    });

    try {
      final page = await _repo.history(widget.unit, page: 1);

      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(page.items);

        _page = page.page;
        _total = page.total;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
      _moreError = null;
    });

    try {
      final page =
      await _repo.history(widget.unit, page: _page + 1);

      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _total = page.total;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _moreError = error;
        _loadingMore = false;
      });
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;

    if (error is StateError &&
        error.message == 'AUTH_REQUIRED') {
      return _t(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        'Your session has expired. Please sign in again.',
      );
    }

    return _t(
      'Vui lòng kiểm tra kết nối và thử lại.',
      'Check your connection and try again.',
    );
  }

  Widget _stateView(
      IconData icon,
      String title, {
        String? detail,
        Widget? action,
      }) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: scheme.outline),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 18),
          Center(child: action),
        ],
      ],
    );
  }

  Widget _line(String label, String value) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry(AcHistoryEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final color = acStatusColor(entry.status, scheme);

    final title = entry.title.isEmpty
        ? _t('Dịch vụ máy lạnh', 'AC service')
        : entry.title;

    final notes = [
      entry.diagnosis,
      entry.serviceNotes,
    ].whereType<String>().join(' · ');

    // Normalize the technician's phone number safely.
    final phone = entry.phone?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    acStatusLabel(entry.status, _vi),
                    style: TextStyle(
                      color: color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _line(
              _t('Thời gian', 'Date'),
              acDateTime(entry.date),
            ),
            _line(
              _t('Kỹ thuật viên', 'Technician'),
              entry.technicianName ?? '—',
            ),

            // Display the phone number only when it is available.
            if (phone != null && phone.isNotEmpty)
              _line(
                _t('Số điện thoại', 'Phone number'),
                phone,
              ),

            _line(
              _t('Mã đơn', 'Booking'),
              entry.bookingCode,
            ),

            if (entry.description != null)
              _line(
                _t('Vị trí máy', 'Unit'),
                entry.description!,
              ),

            if (notes.isNotEmpty)
              _line(
                _t('Ghi chú', 'Notes'),
                notes,
              ),

            if (entry.services.isNotEmpty ||
                entry.additionalWork.isNotEmpty) ...[
              const Divider(height: 24),

              for (final service in entry.services)
                _price(service.name, service.price),

              if (entry.additionalWork.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 2,
                  ),
                  child: Text(
                    _t('Công việc phát sinh', 'Additional work'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final service in entry.additionalWork)
                  _price(service.name, service.price),
              ],
            ],

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Tổng đơn', 'Order total'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  acMoney(entry.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _price(String name, num price) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          acMoney(price),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;

    final title = unit.title.isEmpty
        ? _t(
      'Máy lạnh chưa rõ hãng/model',
      'Unknown brand/model',
    )
        : unit.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_error != null) {
            final notFound = _error is ApiException &&
                (_error as ApiException).code ==
                    'AC_UNIT_NOT_FOUND';

            return RefreshIndicator(
              onRefresh: _loadFirst,
              child: _stateView(
                notFound
                    ? Icons.ac_unit
                    : Icons.wifi_off_rounded,
                notFound
                    ? _t(
                  'Không tìm thấy máy lạnh này',
                  'Air conditioner not found',
                )
                    : _t(
                  'Không thể tải lịch sử',
                  'Unable to load history',
                ),
                detail: _message(_error!),
                action: FilledButton.icon(
                  onPressed: _loadFirst,
                  icon: const Icon(Icons.refresh),
                  label: Text(_t('Thử lại', 'Retry')),
                ),
              ),
            );
          }

          if (_items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadFirst,
              child: _stateView(
                Icons.history,
                _t(
                  'Chưa có lịch sử dịch vụ',
                  'No service history yet',
                ),
                detail: _t(
                  'Các lần bảo dưỡng, sửa chữa sẽ hiển thị tại đây.',
                  'Maintenance and repairs will appear here.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFirst,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                32,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _t(
                      '$_total lần dịch vụ',
                      '$_total services',
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),

                for (final entry in _items) _entry(entry),

                if (_moreError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _message(_moreError!),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                if (_hasMore)
                  Center(
                    child: OutlinedButton(
                      onPressed:
                      _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text(_t('Tải thêm', 'Load more')),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
