import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../models/customer_ac_history.dart';
import '../repositories/ac_history_repository.dart';
import 'ac_history_format.dart';
import 'ac_service_history_page.dart';

/// "My air conditioners": every device the customer has booked service for.
class AcUnitsPage extends StatefulWidget {
  const AcUnitsPage({super.key, this.repository});
  final AcHistoryRepository? repository;

  @override
  State<AcUnitsPage> createState() => _AcUnitsPageState();
}

class _AcUnitsPageState extends State<AcUnitsPage> {
  late final AcHistoryRepository _repo = widget.repository ?? AcHistoryRepository();
  late Future<List<AcUnitGroup>> _future = _repo.units();

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';
  String _t(String vi, String en) => _vi ? vi : en;

  Future<void> _refresh() async {
    setState(() => _future = _repo.units());
    try {
      await _future;
    } catch (_) {
      // FutureBuilder shows the error state.
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    if (error is StateError && error.message == 'AUTH_REQUIRED') {
      return _t('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'Your session has expired. Please sign in again.');
    }
    return _t('Vui lòng kiểm tra kết nối và thử lại.',
        'Check your connection and try again.');
  }

  Widget _state(IconData icon, String title, {String? detail, Widget? action}) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: scheme.outline),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
        if (action != null) ...[const SizedBox(height: 18), Center(child: action)],
      ],
    );
  }

  Widget _card(AcUnitGroup unit) {
    final scheme = Theme.of(context).colorScheme;
    final title = unit.title.isEmpty ? _t('Máy lạnh chưa rõ hãng/model', 'Unknown brand/model') : unit.title;
    final capacity = unit.capacityBtu == null || unit.capacityBtu == 0
        ? null
        : '${unit.capacityBtu!.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} BTU';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AcServiceHistoryPage(unit: unit, repository: _repo))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.ac_unit, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                if (capacity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(capacity,
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                  ),
                const SizedBox(height: 6),
                Text(
                  _t('${unit.serviceCount} lần dịch vụ · ${unit.completedCount} hoàn thành',
                      '${unit.serviceCount} services · ${unit.completedCount} completed'),
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text('${_t('Gần nhất', 'Latest')}: ${acDate(unit.lastServiceAt)}',
                    style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
              ]),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Lịch sử bảo dưỡng máy lạnh', 'AC service history')),
        actions: [
          IconButton(
              onPressed: _refresh,
              tooltip: _t('Làm mới', 'Refresh'),
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<AcUnitGroup>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _state(Icons.wifi_off_rounded, _t('Không thể tải danh sách máy lạnh', 'Unable to load your air conditioners'),
                  detail: _message(snapshot.error!),
                  action: FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(_t('Thử lại', 'Retry')))),
            );
          }
          final units = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: units.isEmpty
                ? _state(Icons.ac_unit, _t('Chưa có máy lạnh nào', 'No air conditioners yet'),
                    detail: _t('Máy lạnh sẽ xuất hiện ở đây sau khi bạn đặt dịch vụ.',
                        'Your air conditioners appear here after you book a service.'))
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _t('Máy được nhóm theo hãng và model từ các đơn đặt dịch vụ của bạn.',
                              'Devices are grouped by brand and model from your bookings.'),
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      for (final unit in units) _card(unit),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
