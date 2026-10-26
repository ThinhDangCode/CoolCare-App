import 'package:flutter/material.dart';
import '../repositories/payment_repository.dart';

/// Customer payment history with payment detail / invoice preview.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key, this.bookingId});
  final String? bookingId;

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _repo = PaymentRepository();
  late Future<Map<String, dynamic>> _future;
  int _page = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PaymentHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingId != widget.bookingId) {
      _page = 1;
      _load();
    }
  }

  void _load() {
    _future = widget.bookingId == null
        ? _repo.history(page: _page, limit: _limit)
        : _repo.summary(widget.bookingId!);
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      // FutureBuilder handles the error state.
    }
  }

  String _t(String vi, String en) =>
      Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

  String _money(dynamic value) {
    final number = (num.tryParse('$value') ?? 0).round();
    final text = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$text ₫';
  }

  int? _statusCode(dynamic raw) {
    final value = '$raw'.toUpperCase();
    switch (value) {
      case '2': case 'SUCCESS': return 2;
      case '0': case 'PENDING': return 0;
      case '1': case 'PROCESSING': return 1;
      case '3': case 'FAILED': return 3;
      case '4': case 'CANCELLED': case 'CANCELED': return 4;
      default: return null;
    }
  }

  String _statusText(int? code) {
    switch (code) {
      case 2: return _t('Thành công', 'Paid');
      case 0: return _t('Chờ thanh toán', 'Pending');
      case 1: return _t('Đang xử lý', 'Processing');
      case 3: return _t('Thất bại', 'Failed');
      case 4: return _t('Đã hủy', 'Cancelled');
      default: return _t('Không xác định', 'Unknown');
    }
  }

  String _date(dynamic value) {
    final dt = DateTime.tryParse('$value')?.toLocal();
    if (dt == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} · ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _method(dynamic raw) {
    switch ('$raw'.toUpperCase()) {
      case 'CASH': case '0': return _t('Tiền mặt', 'Cash');
      case 'VNPAY': return 'VNPay';
      case 'ZALOPAY': return 'ZaloPay';
      case 'ONLINE': case '1': return _t('Trực tuyến', 'Online');
      default: return raw == null ? '—' : '$raw';
    }
  }

  Widget _stateView({required IconData icon, required String title,
    String? detail, Widget? action}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: scheme.outline),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
        if (action != null) ...[const SizedBox(height: 18), action],
      ]),
    ));
  }

  Widget _paymentCard(Map<String, dynamic> payment) {
    final scheme = Theme.of(context).colorScheme;
    final code = _statusCode(payment['payment_status']);
    final success = code == 2;
    final failed = code == 3 || code == 4;
    final statusColor = success ? const Color(0xFF13856A)
        : failed ? scheme.error : const Color(0xFFB07716);
    final statusBg = statusColor.withValues(alpha: 0.10);
    final method = _method(payment['method_code'] ?? payment['payment_method']);
    final paymentCode = payment['payment_code']?.toString();
    final bookingId = payment['booking_id']?.toString();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7))),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _PaymentInvoicePreviewPage(payment: payment),
        )),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.payments_outlined, color: scheme.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(method, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Text(_date(payment['paid_at'] ?? payment['created_at']),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_money(payment['amount']),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(success ? Icons.check_circle_outline : failed ? Icons.cancel_outlined
                  : Icons.schedule_outlined, size: 15, color: statusColor),
                const SizedBox(width: 5),
                Text(_statusText(code), style: TextStyle(color: statusColor,
                  fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
          ]),
          if ((paymentCode != null && paymentCode.isNotEmpty) ||
              (widget.bookingId == null && bookingId != null)) ...[
            const SizedBox(height: 12),
            Divider(color: scheme.outlineVariant),
            if (paymentCode != null && paymentCode.isNotEmpty)
              _meta(_t('Mã giao dịch', 'Payment code'), paymentCode),
            if (widget.bookingId == null && bookingId != null)
              _meta(_t('Mã đơn', 'Booking ID'), bookingId),
          ],
          // Tap the card to open payment details and invoice preview.
        ],
      ))),
    );
  }

  Widget _meta(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(top: 5), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Lịch sử thanh toán', 'Payment History')),
        actions: [IconButton(onPressed: _refresh,
          tooltip: _t('Làm mới', 'Refresh'), icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _stateView(
              icon: Icons.wifi_off_rounded,
              title: _t('Không thể tải lịch sử', 'Unable to load history'),
              detail: _t(
                'Vui lòng kiểm tra kết nối và thử lại.',
                'Check your connection and try again.',
              ),
              action: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(_t('Thử lại', 'Retry')),
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final payments = (data['payments'] as List? ?? const [])
            .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final total = int.tryParse('${data['total']}') ?? payments.length;
          final paid = payments.where((p) => _statusCode(p['payment_status']) == 2)
            .fold<num>(0, (sum, p) => sum + (num.tryParse('${p['amount']}') ?? 0));
          final pages = (total + _limit - 1) ~/ _limit;
          return RefreshIndicator(onRefresh: _refresh, child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.account_balance_wallet_outlined,
                      color: scheme.onPrimaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.bookingId == null
                      ? _t('Đã thanh toán trong trang này', 'Paid on this page')
                      : _t('Tổng đã thanh toán', 'Total paid'),
                      style: TextStyle(color: scheme.onPrimaryContainer))),
                  ]),
                  const SizedBox(height: 12),
                  Text(_money(paid), style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 8),
                  Text(_t('$total giao dịch', '$total transactions'),
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                ])),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Text(_t('Giao dịch của bạn', 'Your transactions'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                Text('$total', style: TextStyle(color: scheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: scheme.outline),
                    const SizedBox(height: 12),
                    Text(_t('Chưa có lịch sử thanh toán', 'No payment history yet'),
                      style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(_t('Các giao dịch sẽ hiển thị tại đây.',
                      'Your transactions will appear here.'),
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  ]))
              else
                for (final payment in payments) _paymentCard(payment),
              if (widget.bookingId == null && pages > 1)
                Padding(padding: const EdgeInsets.only(top: 8), child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(onPressed: _page > 1 ? () => setState(() {
                      _page--; _load();
                    }) : null, icon: const Icon(Icons.chevron_left)),
                    Text('${_t('Trang', 'Page')} $_page / $pages'),
                    IconButton(onPressed: _page < pages ? () => setState(() {
                      _page++; _load();
                    }) : null, icon: const Icon(Icons.chevron_right)),
                  ])),
            ],
          ));
        },
      ),
    );
  }
}

/// Displays payment information as a preview, not an issued tax invoice.
/// Download stays disabled until a verified invoice endpoint is available.
class _PaymentInvoicePreviewPage extends StatelessWidget {
  const _PaymentInvoicePreviewPage({required this.payment});
  final Map<String, dynamic> payment;

  String _t(BuildContext context, String vi, String en) =>
      Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

  String _money(dynamic raw) {
    final value = (num.tryParse('$raw') ?? 0).round();
    return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';
  }

  String _date(dynamic raw) {
    final date = DateTime.tryParse('$raw')?.toLocal();
    if (date == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  String _status(BuildContext context, dynamic raw) {
    switch ('$raw'.toUpperCase()) {
      case '2': case 'SUCCESS': return _t(context, 'Đã thanh toán', 'Paid');
      case '0': case 'PENDING': return _t(context, 'Chờ thanh toán', 'Pending');
      case '1': case 'PROCESSING': return _t(context, 'Đang xử lý', 'Processing');
      case '3': case 'FAILED': return _t(context, 'Thất bại', 'Failed');
      case '4': case 'CANCELLED': case 'CANCELED': return _t(context, 'Đã hủy', 'Cancelled');
      default: return _t(context, 'Không xác định', 'Unknown');
    }
  }

  Widget _detail(BuildContext context, String title, dynamic value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 116, child: Text(title,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
        Expanded(child: SelectableText(value == null || '$value'.isEmpty ? '—' : '$value',
          textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final method = '${payment['method_code'] ?? payment['payment_method'] ?? '—'}';
    final methodText = switch (method.toUpperCase()) {
      'CASH' || '0' => _t(context, 'Tiền mặt', 'Cash'),
      'VNPAY' => 'VNPay',
      'ZALOPAY' => 'ZaloPay',
      _ => method,
    };
    final paid = ['2', 'SUCCESS'].contains('${payment['payment_status']}'.toUpperCase());
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'Chi tiết thanh toán', 'Payment details'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(22)),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 42, color: scheme.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(_money(payment['amount']), style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(_status(context, payment['payment_status']),
              style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant)),
          child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            _detail(context, _t(context, 'Mã giao dịch', 'Payment code'), payment['payment_code']),
            const Divider(),
            _detail(context, _t(context, 'Mã booking', 'Booking ID'), payment['booking_id']),
            const Divider(),
            _detail(context, _t(context, 'Phương thức', 'Method'), methodText),
            const Divider(),
            _detail(context, _t(context, 'Thời gian', 'Date'),
              _date(payment['paid_at'] ?? payment['created_at'])),
            if (payment['transaction_reference'] != null) ...[
              const Divider(),
              _detail(context, _t(context, 'Mã đối soát', 'Reference'),
                payment['transaction_reference']),
            ],
          ])),
        ),
        const SizedBox(height: 14),
        Text(_t(context,
          'Đây là thông tin giao dịch, chưa phải hóa đơn được phát hành.',
          'This is a payment summary, not an issued invoice.'),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.download_outlined),
          label: Text(_t(context, 'Tải hóa đơn (sắp có)', 'Download invoice (coming soon)')),
        )),
        if (!paid) Padding(padding: const EdgeInsets.only(top: 8), child: Text(
          _t(context, 'Giao dịch chưa hoàn tất thanh toán.', 'Payment is not completed.'),
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
      ]),
    );
  }
}
