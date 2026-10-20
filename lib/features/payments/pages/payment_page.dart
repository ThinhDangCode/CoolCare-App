import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../repositories/payment_repository.dart';
import 'payment_history_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.bookingId,
    this.technician = false,
  });

  final String bookingId;
  final bool technician;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with WidgetsBindingObserver {
  final _repo = PaymentRepository();

  bool _busy = false;
  bool _loading = true;
  bool _refreshing = false;
  bool _reconciling = false;
  bool _hadPaymentSuccess = false;

  String _method = 'CASH';
  bool _onlineChoice = false;
  String? _error;
  String? _notice;

  // Thông tin checkout vừa tạo trong phiên (kỹ thuật viên).
  String? _checkoutUrl;
  String? _techQrData;

  Timer? _statusTimer;

  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _cash = [];

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';

  String tr(String vi, String en) => _vi ? vi : en;

  String money(dynamic value) {
    final n = num.tryParse('$value') ?? 0;

    final formatted = n.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
    );

    return '$formatted ₫';
  }

  String statusText(String? status) {
    switch (status) {
      case 'SUCCESS':
        return tr('Thành công', 'Successful');
      case 'PENDING':
        return tr('Chờ xác nhận', 'Pending');
      case 'PROCESSING':
        return tr('Đang xử lý', 'Processing');
      case 'FAILED':
        return tr('Thất bại', 'Failed');
      case 'CANCELLED':
        return tr('Đã hủy', 'Cancelled');
      default:
        return status ?? tr('Không rõ', 'Unknown');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _refresh();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_busy && !_refreshing) _refresh();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lại app (ví dụ sau khi thanh toán ở app ZaloPay): tải lại ngay.
    if (state == AppLifecycleState.resumed && !_refreshing) {
      _refresh();
    }
  }

  List<Map<String, dynamic>> _payments() {
    final rows = _data?['payments'] as List? ?? [];

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  /// Hỏi ZaloPay về các đơn ZaloPay đang PENDING.
  /// Backend chỉ cho kỹ thuật viên được giao đơn gọi reconcile.
  Future<bool> _reconcilePendingZalo(List<Map<String, dynamic>> rows) async {
    final pending = rows
        .where((p) =>
    p['method_code'] == 'ZALOPAY' &&
        p['payment_status'] == 'PENDING' &&
        p['id'] != null)
        .toList();

    if (pending.isEmpty || _reconciling) return false;

    _reconciling = true;
    try {
      for (final p in pending) {
        try {
          await _repo.reconcileZaloPay('${p['id']}');
        } catch (_) {
          // Cổng không phản hồi / chưa rõ: giữ nguyên PENDING.
        }
      }
    } finally {
      _reconciling = false;
    }
    return true;
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    if (_data == null) setState(() => _loading = true);

    try {
      if (widget.technician) {
        var result = await _repo.technicianSummary(widget.bookingId);
        var rows = (result['payments'] as List? ?? [])
            .whereType<Map>()
            .map((p) => Map<String, dynamic>.from(p))
            .toList();

        // Chủ động đối chiếu với ZaloPay, không chỉ chờ callback ngrok.
        if (await _reconcilePendingZalo(rows)) {
          result = await _repo.technicianSummary(widget.bookingId);
          rows = (result['payments'] as List? ?? [])
              .whereType<Map>()
              .map((p) => Map<String, dynamic>.from(p))
              .toList();
        }

        if (!mounted) return;

        final success = rows.any((p) => p['payment_status'] == 'SUCCESS');

        setState(() {
          _data = result;
          _cash = rows;
          if (success && !_hadPaymentSuccess) {
            _notice = tr(
              'Giao dịch thanh toán thành công!',
              'Payment successful!',
            );
            _checkoutUrl = null;
            _techQrData = null;
          }
          _hadPaymentSuccess = success;
          _error = null;
        });
      } else {
        // Khách chỉ xem trạng thái; reconcile do kỹ thuật viên thực hiện.
        final result = await _repo.summary(widget.bookingId);

        if (!mounted) return;

        setState(() {
          _data = result;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      _refreshing = false;
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await task();
      await _refresh();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _techCreate(num total) async {
    final method = total == 0 ? 'FREE' : _method;
    final key =
        'coolcare_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

    final created = await _repo.create(widget.bookingId, method, key);

    if (method == 'FREE' || method == 'CASH') return;

    final id = created['id']?.toString();
    if (id == null || id.isEmpty) throw StateError('PAYMENT_ID_MISSING');

    final checkout = await _repo.checkout(id);

    if (!mounted) return;

    final url = checkout['url']?.toString();
    final qrData = method == 'ZALOPAY' ? checkout['qrData']?.toString() : url;
    final hasUrl = url != null && url.isNotEmpty;
    final hasQr = qrData != null && qrData.isNotEmpty;

    setState(() {
      _checkoutUrl = hasUrl ? url : null;
      _techQrData = hasQr ? qrData : null;

      if (method == 'ZALOPAY') {
        _notice = (hasUrl || hasQr)
            ? tr(
          'Đã tạo mã thanh toán. Hãy để khách quét QR bằng ZaloPaySB.',
          'Payment QR is ready. Ask the customer to scan with ZaloPaySB.',
        )
            : tr(
          'ZaloPay đã tạo đơn nhưng không trả QR hay liên kết. '
              'Bấm làm mới để kiểm tra trạng thái; không tạo thêm giao dịch.',
          'ZaloPay created the order but returned no QR or link. '
              'Refresh to check status; do not create another payment.',
        );
      } else {
        _notice = tr(
          'Đã tạo mã QR VNPay. Khách quét bằng camera để mở trang thanh toán.',
          'VNPay QR is ready. Scan with a phone camera to open checkout.',
        );
      }
    });
  }

  Widget _messageCard(
      String message, {
        bool error = false,
      }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              color: error
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  Widget _technicianContent() {
    final booking =
        (_data?['booking'] as Map?)?.cast<String, dynamic>() ?? {};
    final total = num.tryParse('${booking['total_amount']}') ?? 0;
    final confirmed = booking['charges_confirmed_at'] != null;
    final completed = booking['status'] == 'COMPLETED';
    final paid = _cash.any((p) => p['payment_status'] == 'SUCCESS');
    final pending = _cash.where((p) =>
        ['PENDING', 'PROCESSING'].contains(p['payment_status'])).toList();
    final current = pending.isNotEmpty ? pending.first : null;
    final methodCode = current?['method_code']?.toString() ?? _method;
    final stored = current?['checkout_url']?.toString();
    final storedIsLink = stored != null && stored.startsWith('https://');
    final isZalo = current != null && methodCode == 'ZALOPAY';
    final isVnpay = current != null && methodCode == 'VNPAY';
    final qrData = (isZalo || isVnpay)
        ? (_techQrData ??
            ((stored != null && stored.isNotEmpty && !storedIsLink)
                ? stored
                : null) ??
            _checkoutUrl ??
            (storedIsLink ? stored : null))
        : null;
    final hasQr = qrData != null && qrData.isNotEmpty;
    final isCash = current?['payment_kind'] == 'CASH';
    final isWaiting = current != null;
    final statusColor = paid
        ? const Color(0xFF087C65)
        : isWaiting
            ? const Color(0xFF946500)
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final statusBg = paid
        ? const Color(0xFFE9F7F2)
        : isWaiting
            ? const Color(0xFFFFF6E3)
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Tổng thanh toán', 'Total payment'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(money(total),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                if (paid) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF087C65), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tr('Thanh toán thành công',
                            'Payment successful')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!paid && (!confirmed || !completed)) ...[
          const SizedBox(height: 12),
          _messageCard(tr(
            'Chờ khách xác nhận hoàn thành và tổng tiền.',
            'Await customer completion and final price approval.',
          )),
        ],
        if (!paid && !isWaiting && completed && confirmed) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr('Phương thức thanh toán', 'Payment method'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (total > 0) ...[
                    Row(
                      children: [
                        Expanded(child: _paymentChoice(
                          online: false,
                          title: tr('Tiền mặt', 'Cash'),
                          subtitle: tr('Nhận tiền trực tiếp', 'Receive cash'),
                          icon: Icons.payments_rounded,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _paymentChoice(
                          online: true,
                          title: tr('Tạo mã QR', 'Generate QR'),
                          subtitle: tr('Thanh toán trực tuyến', 'Pay online'),
                          icon: Icons.qr_code_2_rounded,
                        )),
                      ],
                    ),
                    if (_onlineChoice) ...[
                      const SizedBox(height: 14),
                      Text(tr('Chọn cổng thanh toán', 'Choose payment provider'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _gatewayChoice('ZALOPAY', 'ZaloPay', Icons.account_balance_wallet_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _gatewayChoice('VNPAY', 'VNPay', Icons.account_balance_rounded)),
                      ]),
                    ],
                  ],
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(() => _techCreate(total)),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(_onlineChoice ? tr('Tạo mã QR', 'Generate QR') : tr('Tạo thanh toán tiền mặt', 'Create cash payment')),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!paid && isWaiting) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(isCash ? Icons.payments_outlined : Icons.qr_code_2,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          methodCode == 'ZALOPAY'
                              ? 'ZaloPay'
                              : methodCode == 'VNPAY'
                                  ? 'VNPay'
                                  : tr('Tiền mặt', 'Cash'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  if (hasQr) ...[
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6E9ED)),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 228,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isVnpay
                        ? tr('Khách quét QR bằng camera điện thoại để mở trang VNPay và thanh toán.', 'Scan with a phone camera to open VNPay checkout.')
                        : tr('Khách quét mã QR bằng ứng dụng ZaloPay để thanh toán.', 'Ask the customer to scan the QR code with ZaloPay.'),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (isZalo) ...[
                    const SizedBox(height: 14),
                    _messageCard(tr(
                      'Chưa có mã QR. Vui lòng làm mới để kiểm tra giao dịch.',
                      'QR is not available. Refresh to check the payment.',
                    )),
                  ] else if (methodCode == 'VNPAY') ...[
                    const SizedBox(height: 14),
                    Text(tr('Giao dịch VNPay đang chờ khách thanh toán.',
                        'VNPay payment is awaiting customer completion.')),
                  ],
                  if (isCash) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() =>
                              _repo.confirmCash('${current['id']}')),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(tr('Xác nhận đã nhận tiền',
                          'Confirm cash received')),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync_rounded, size: 17),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            tr('Tự động kiểm tra trạng thái thanh toán',
                                'Payment status updates automatically'),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _paymentChoice({required bool online, required String title,
      required String subtitle, required IconData icon}) {
    final selected = _onlineChoice == online;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _busy ? null : () => setState(() {
        _onlineChoice = online;
        _method = online ? 'ZALOPAY' : 'CASH';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(.07) : Colors.white,
          border: Border.all(color: selected ? primary : const Color(0xFFE0E6EA), width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(icon, color: primary, size: 32),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? primary : Colors.grey, size: 19),
        ]),
      ),
    );
  }

  Widget _gatewayChoice(String code, String title, IconData icon) {
    final selected = _method == code;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: _busy ? null : () => setState(() => _method = code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? primary : const Color(0xFFE0E6EA), width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected ? primary.withOpacity(.06) : Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 7),
          Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (selected) ...[const SizedBox(width: 4), Icon(Icons.check_circle, size: 16, color: primary)],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking =
        (_data?['booking'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final payments = _payments();

    final total = num.tryParse('${booking['total_amount']}') ?? 0;

    final ready = booking['status'] == 'COMPLETED';

    final confirmed = booking['charges_confirmed_at'] != null;

    final paid = payments.any(
          (p) =>
      p['payment_status'] == 'SUCCESS' &&
          (num.tryParse('${p['amount']}') ?? -1) == total,
    );

    final processing = payments.any(
          (p) => ['PENDING', 'PROCESSING'].contains(p['payment_status']),
    );
    final cashPending = payments.any((p) =>
    p['method_code'] == 'CASH' &&
        ['PENDING', 'PROCESSING'].contains(p['payment_status']));

    final canPay = ready && confirmed && !paid && !processing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.technician
              ? tr('Thanh toán kỹ thuật viên', 'Technician Payment')
              : tr('Thanh toán CoolCare', 'CoolCare Payment'),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: tr('Làm mới', 'Refresh'),
          ),
        ],
      ),
      body: _loading && _data == null && _cash.isEmpty
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              _messageCard(
                _error == 'Bad state: AUTH_REQUIRED'
                    ? tr('Vui lòng đăng nhập.', 'Please sign in.')
                    : '${tr('Có lỗi xảy ra', 'An error occurred')}: $_error',
                error: true,
              ),
            if (!widget.technician && _notice != null) _messageCard(_notice!),
            if (widget.technician)
              _technicianContent()
            else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: paid
                      ? const Color(0xFFE9F7F2)
                      : const Color(0xFFFFF6E3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(
                    paid
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: paid
                        ? const Color(0xFF087C65)
                        : const Color(0xFF946500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paid
                              ? tr('Đã thanh toán', 'Paid')
                              : processing
                              ? (cashPending
                              ? tr(
                              'Chờ kỹ thuật viên xác nhận tiền mặt',
                              'Awaiting technician cash confirmation')
                              : tr('Chờ xác minh thanh toán',
                              'Payment verification pending'))
                              : ready
                              ? tr('Chưa thanh toán', 'Unpaid')
                              : tr('Chưa đến bước thanh toán',
                              'Payment not yet due'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          paid
                              ? tr('Thanh toán đã được xác nhận.',
                              'Payment confirmed.')
                              : ready
                              ? tr(
                              'Công việc đã hoàn thành. Hãy kiểm tra hóa đơn và chờ kỹ thuật viên tạo thanh toán.',
                              'Service completed. Review the bill and wait for the technician to create payment.')
                              : tr(
                              'Thanh toán sau khi hoàn thành dịch vụ.',
                              'Pay after service completion.'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Tổng thanh toán', 'Total Payment'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(total),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${tr('Tạm tính', 'Subtotal')}: '
                            '${money(booking['subtotal'])}',
                      ),
                      Text(
                        '${tr('Giảm giá', 'Discount')}: '
                            '${money(booking['discount_amount'])}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (paid)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      tr('Thanh toán thành công', 'Payment Successful'),
                    ),
                    subtitle: Text(
                      tr('Đơn hàng đã được thanh toán.',
                          'The booking has been paid.'),
                    ),
                  ),
                )
              else if (!ready)
                _messageCard(
                  tr(
                    'Công việc cần được xác nhận hoàn thành trước khi thanh toán.',
                    'The service must be completed before payment.',
                  ),
                )
              else if (!confirmed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Xác nhận chi phí cuối cùng',
                                'Confirm Final Charges'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              'Vui lòng kiểm tra tổng tiền trước khi thanh toán.',
                              'Review the total before payment.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                              await _repo
                                  .confirmCharges(widget.bookingId);
                            }),
                            child: Text(
                              tr('Xác nhận chi phí', 'Confirm Charges'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (processing)
                    _messageCard(
                      tr(
                        'Giao dịch đang chờ xác minh. Vui lòng không tạo thêm giao dịch; kỹ thuật viên sẽ hỗ trợ nếu thanh toán thất bại.',
                        'A payment is pending. Check its status below.',
                      ),
                    ),
              if (canPay)
                _messageCard(tr(
                  'Đã xác nhận tổng tiền. Kỹ thuật viên sẽ tạo mã thanh toán để bạn quét.',
                  'Technician will generate payment QR after your approval.',
                )),
              if (!paid && ready && confirmed && processing)
                _messageCard(tr(
                  'Vui lòng thanh toán bằng ứng dụng hoặc trang thanh toán bên ngoài theo hướng dẫn của kỹ thuật viên. CoolCare sẽ tự cập nhật khi cổng thanh toán xác nhận.',
                  'Complete payment using the external app or checkout page shown by the technician. CoolCare updates automatically after gateway confirmation.',
                )),
              if (!paid && ready && confirmed && !processing)
                _messageCard(tr(
                  'Vui lòng yêu cầu kỹ thuật viên tạo mã thanh toán trên thiết bị của họ. Bạn không cần tạo giao dịch trong CoolCare.',
                  'Ask the technician to generate the payment code on their device. You do not need to create a payment in CoolCare.',
                )),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PaymentHistoryPage(
                        bookingId: widget.bookingId,
                      ),
                    ),
                  );
                  if (mounted) await _refresh();
                },
                icon: const Icon(Icons.history),
                label: Text(
                  tr('Xem lịch sử thanh toán', 'View Payment History'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}