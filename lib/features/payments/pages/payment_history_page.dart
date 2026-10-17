import 'package:flutter/material.dart';

import '../repositories/payment_repository.dart';

/// Trang lịch sử thanh toán độc lập, chỉ đọc dữ liệu từ backend.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final PaymentRepository _repository = PaymentRepository();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repository.summary(widget.bookingId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _future;
    } catch (_) {
      // FutureBuilder hiển thị lỗi.
    }
  }

  String _t(BuildContext context, String vi, String en) =>
      Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

  String _money(dynamic amount) {
    final value = (num.tryParse('$amount') ?? 0).round();
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$formatted ₫';
  }

  String _status(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return _t(context, 'Đã thanh toán', 'Paid');
      case 'PENDING':
        return _t(context, 'Chờ thanh toán', 'Pending');
      case 'PROCESSING':
        return _t(context, 'Đang xử lý', 'Processing');
      case 'FAILED':
        return _t(context, 'Thất bại', 'Failed');
      case 'CANCELLED':
      case 'CANCELED':
        return _t(context, 'Đã hủy', 'Canceled');
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF087C65);
      case 'FAILED':
      case 'CANCELLED':
      case 'CANCELED':
        return Theme.of(context).colorScheme.error;
      default:
        return const Color(0xFF9A6A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF078B96);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Lịch sử thanh toán', 'Payment History')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: _t(context, 'Làm mới', 'Refresh'),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_outlined, size: 40),
                    const SizedBox(height: 12),
                    Text(_t(context, 'Không tải được lịch sử thanh toán.',
                        'Unable to load payment history.')),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh,
                        child: Text(_t(context, 'Thử lại', 'Retry'))),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data ?? {};
          final rows = (data['payments'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final paid = rows.where((e) =>
              e['payment_status']?.toString().toUpperCase() == 'SUCCESS');
          final totalPaid = paid.fold<num>(0, (sum, row) =>
              sum + (num.tryParse('${row['amount']}') ?? 0));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t(context, 'Tổng đã thanh toán', 'Total paid'),
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(_money(totalPaid),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 6),
                      Text('${rows.length} ${_t(context, 'giao dịch', 'transactions')}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(_t(context, 'Giao dịch của đơn hàng', 'Booking transactions'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  Card(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_t(context, 'Chưa có giao dịch thanh toán.',
                        'No payment transactions yet.')),
                  )),
                for (final row in rows) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.receipt_long_outlined, color: teal),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              '${row['method_code'] ?? row['provider'] ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            )),
                            Text(_money(row['amount']),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 10),
                          Text(
                            _status(context, '${row['payment_status'] ?? ''}'),
                            style: TextStyle(
                              color: _statusColor(context,
                                  '${row['payment_status'] ?? ''}'),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (row['created_at'] != null) ...[
                            const SizedBox(height: 4),
                            Text('${row['created_at']}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                          if (row['payment_code'] != null) ...[
                            const SizedBox(height: 4),
                            Text('${_t(context, 'Mã giao dịch', 'Payment code')}: '
                                '${row['payment_code']}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
