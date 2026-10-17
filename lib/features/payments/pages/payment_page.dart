
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/payment_repository.dart';
import '../services/zalopay_app_to_app.dart';
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

  StreamSubscription<ZaloPayResult>? _zaloSubscription;

  bool _busy = false;
  bool _loading = true;
  bool _awaitingExternalPayment = false;

  String _method = 'CASH';
  String? _error;
  String? _notice;
  String? _checkoutUrl;
  String? _activeVnpayPaymentId;
  String? _activeZaloPaymentId;
  String? _activeZaloToken;
  bool _checkingReturn = false;
  bool _reconcilingOnRefresh = false;

  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _cash = [];

  bool get _vi =>
      Localizations.localeOf(context).languageCode == 'vi';

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

    if (!widget.technician) {
      _zaloSubscription =
          ZaloPayAppToApp.paymentResults.listen(
            _onZaloPayResult,
            onError: (Object error) {
              if (!mounted) return;

              setState(() {
                _error = error.toString();
              });
            },
          );
    }

    _refresh();
  }

  @override
  void dispose() {
    _zaloSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.resumed && !widget.technician) {
      _checkReturningPayment();
    }
  }

  Future<void> _checkReturningPayment() async {
    if (_checkingReturn) return;
    _checkingReturn = true;
    try {
    final id = _activeZaloPaymentId;

    if (id != null) {
      try {
        await _repo.reconcileZaloPay(id);
      } catch (_) {
        // Vẫn tải trạng thái hiện có từ backend.
      }
    }

    await _refresh();
    if (!mounted) return;
    final settled = _payments().any((p) =>
        p['id']?.toString() == id && p['payment_status'] == 'SUCCESS');
    final closed = _payments().any((p) =>
        p['id']?.toString() == id &&
        ['FAILED', 'CANCELLED'].contains(p['payment_status']));
    if (settled || closed) {
      setState(() {
        _awaitingExternalPayment = false;
        _activeZaloPaymentId = null;
        _activeZaloToken = null;
        if (closed) {
          _notice = tr(
            'Giao dịch ZaloPay không thành công. Bạn có thể thanh toán lại.',
            'ZaloPay failed. You can retry payment.',
          );
        }
      });
    }
    final vnpayId = _activeVnpayPaymentId;
    if (vnpayId != null) {
      final transaction = _payments().where(
        (p) => p['id']?.toString() == vnpayId,
      );
      if (transaction.isNotEmpty &&
          transaction.first['payment_status'] == 'SUCCESS') {
        setState(() {
          _activeVnpayPaymentId = null;
          _checkoutUrl = null;
          _awaitingExternalPayment = false;
          _notice = tr('VNPay đã được backend xác nhận thanh toán.',
              'VNPay payment verified by the backend.');
        });
      } else if (transaction.isNotEmpty &&
          ['FAILED', 'CANCELLED'].contains(transaction.first['payment_status'])) {
        setState(() {
          _activeVnpayPaymentId = null;
          _checkoutUrl = null;
          _awaitingExternalPayment = false;
          _notice = tr('VNPay không thành công. Bạn có thể thanh toán lại.',
              'VNPay failed. You can retry payment.');
        });
      } else {
        setState(() {
          _awaitingExternalPayment = false;
          _notice = tr(
            'Chưa nhận được xác nhận từ VNPay. Vui lòng kiểm tra lại; '
            'không tạo giao dịch mới khi giao dịch cũ còn chờ.',
            'VNPay has not been confirmed. Check again before retrying.',
          );
        });
      }
    }
    } finally {
      _checkingReturn = false;
    }
  }

  Future<void> _onZaloPayResult(
      ZaloPayResult result,
      ) async {
    final id = _activeZaloPaymentId;
    if (id == null || !mounted) return;

    setState(() {
      _notice = result.isSuccess
          ? tr(
        'ZaloPay đã trả kết quả. Đang xác minh giao dịch.',
        'ZaloPay returned a result. Verifying payment.',
      )
          : result.isCanceled
          ? tr(
        'Bạn đã hủy thanh toán ZaloPay.',
        'You canceled the ZaloPay payment.',
      )
          : tr(
        'ZaloPay gặp lỗi. Hãy kiểm tra trạng thái giao dịch.',
        'ZaloPay encountered an error. Check payment status.',
      );
    });

    try {
      await _repo.reconcileZaloPay(id);
    } catch (_) {
      // Không coi callback SDK là bằng chứng thanh toán.
    }

    await _refresh();

    if (!mounted) return;

    final payments = _payments();
    final isPaid = payments.any(
          (p) =>
      p['id']?.toString() == id &&
          p['payment_status'] == 'SUCCESS',
    );

    setState(() {
      if (isPaid) {
        _notice = tr(
          'Thanh toán ZaloPay thành công.',
          'ZaloPay payment successful.',
        );
        _awaitingExternalPayment = false;
        _activeZaloPaymentId = null;
        _activeZaloToken = null;
      } else if (payments.any((p) =>
          p['id']?.toString() == id &&
          ['FAILED', 'CANCELLED'].contains(p['payment_status']))) {
        _notice = tr(
          'Giao dịch đã thất bại hoặc bị hủy. Bạn có thể chọn phương thức và thanh toán lại.',
          'Payment failed or was canceled. You can choose a method and retry.',
        );
        _awaitingExternalPayment = false;
        _activeZaloPaymentId = null;
        _activeZaloToken = null;
      } else if (result.isSuccess) {
        _notice = tr(
          'Giao dịch đang chờ backend xác minh. '
              'Bạn có thể bấm Kiểm tra thanh toán.',
          'Payment is awaiting backend verification. '
              'You can check the payment status.',
        );
      }
    });
  }

  List<Map<String, dynamic>> _payments() {
    final rows = _data?['payments'] as List? ?? [];

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      if (widget.technician) {
        final rows = await _repo.cashForTechnician(
          widget.bookingId,
        );

        if (!mounted) return;

        setState(() {
          _cash = rows;
          _error = null;
        });
      } else {
        var result = await _repo.summary(widget.bookingId);
        final rows = result['payments'] as List? ?? const [];
        final pendingZalo = rows.whereType<Map>().where((p) =>
          p['method_code'] == 'ZALOPAY' &&
          p['payment_status'] == 'PENDING' && p['id'] != null).toList();
        if (pendingZalo.isNotEmpty && !_reconcilingOnRefresh) {
          _reconcilingOnRefresh = true;
          try {
            for (final p in pendingZalo) {
              try {
                await _repo.reconcileZaloPay('${p['id']}');
              } catch (_) {
                // Gateway unreachable/unknown: preserve PENDING.
              }
            }
            result = await _repo.summary(widget.bookingId);
          } finally {
            _reconcilingOnRefresh = false;
          }
        }

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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _run(
      Future<void> Function() task,
      ) async {
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

  Future<void> _pay(num total) async {
    final method = total == 0 ? 'FREE' : _method;

    final key =
        'coolcare_${DateTime.now().microsecondsSinceEpoch}_'
        '${Random.secure().nextInt(1 << 32)}';

    final created = await _repo.create(
      widget.bookingId,
      method,
      key,
    );

    if (method == 'CASH' || method == 'FREE') {
      return;
    }

    final paymentId = created['id']?.toString();

    if (paymentId == null || paymentId.isEmpty) {
      throw StateError('PAYMENT_ID_MISSING');
    }

    final checkout = await _repo.checkout(paymentId);

    if (method == 'ZALOPAY') {
      final token = checkout['zpTransToken']?.toString();

      if (token == null || token.isEmpty) {
        throw StateError('ZALOPAY_TOKEN_MISSING');
      }

      if (mounted) {
        setState(() {
          _activeZaloPaymentId = paymentId;
          _activeZaloToken = token;
          _awaitingExternalPayment = true;
          _checkoutUrl = null;
          _notice = tr(
            'Đang chuyển sang ZaloPay...',
            'Opening ZaloPay...',
          );
        });
      }

      await ZaloPayAppToApp.payOrder(token);
      return;
    }

    _activeVnpayPaymentId = paymentId;
    await _openCheckoutUrl(checkout);
  }

  Future<void> _openCheckoutUrl(
      Map<String, dynamic> checkout,
      ) async {
    final url = checkout['url']?.toString();

    if (url == null || url.isEmpty) {
      throw StateError('CHECKOUT_URL_MISSING');
    }

    final uri = Uri.tryParse(url);

    if (uri == null || uri.scheme != 'https') {
      throw StateError('INVALID_CHECKOUT_URL');
    }

    if (mounted) {
      setState(() {
        _checkoutUrl = url;
        _awaitingExternalPayment = true;
        _activeZaloPaymentId = null;
        _activeZaloToken = null;
      });
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw StateError('CHECKOUT_OPEN_FAILED');
    }
  }

  Future<void> _resumeOnlinePayment(
      String paymentId,
      String methodCode,
      ) async {
    if (methodCode == 'ZALOPAY') {
      final result = await _repo.reconcileZaloPay(paymentId);
      if (!mounted) return;
      if (result['status'] == 'SUCCESS') {
        setState(() {
          _notice = tr('Thanh toán đã được xác nhận.', 'Payment confirmed.');
          _activeZaloPaymentId = null;
          _activeZaloToken = null;
          _awaitingExternalPayment = false;
        });
      } else {
        final token = _activeZaloPaymentId == paymentId
            ? _activeZaloToken : null;
        if (token != null && token.isNotEmpty) {
          setState(() {
            _notice = tr('Đang mở lại ZaloPay bằng token trong phiên.',
                'Reopening ZaloPay using the current session token.');
          });
          await ZaloPayAppToApp.payOrder(token);
        } else {
          setState(() {
            _notice = tr(
              'Giao dịch chưa được xác nhận. Vui lòng liên hệ hỗ trợ '
              'nếu vẫn đang chờ sau khi kiểm tra lại.',
              'Payment not confirmed. Contact support if it remains pending.',
            );
          });
        }
      }
      return;
    }

    // Refresh first: the old VNPay callback might have arrived.
    await _refresh();
    if (!mounted) return;
    final matching = _payments().where(
      (p) => p['id']?.toString() == paymentId,
    );
    if (matching.isEmpty) {
      throw StateError('PAYMENT_NOT_FOUND');
    }
    final status = matching.first['payment_status']?.toString();
    if (status == 'SUCCESS') {
      setState(() => _notice = tr(
        'VNPay đã thanh toán thành công.',
        'VNPay payment confirmed.',
      ));
      return;
    }
    if (status != 'PENDING') {
      setState(() => _notice = tr(
        'Giao dịch không còn ở trạng thái chờ. Vui lòng tải lại.',
        'Payment is no longer pending. Please refresh.',
      ));
      return;
    }

    // Reopen the same checkout URL when available; no new payment attempt.
    if (_activeVnpayPaymentId == paymentId && _checkoutUrl != null) {
      final uri = Uri.tryParse(_checkoutUrl!);
      if (uri != null && uri.scheme == 'https') {
        final launched = await launchUrl(
          uri, mode: LaunchMode.externalApplication,
        );
        if (!launched) throw StateError('CHECKOUT_OPEN_FAILED');
        return;
      }
    }

    // Reuse the same payment ID, never create a second payment record.
    // The gateway may still have completed an earlier checkout; obtain
    // explicit confirmation before opening another checkout session.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Thanh toán lại VNPay', 'Retry VNPay payment')),
        content: Text(tr(
          'Giao dịch cũ vẫn đang PENDING. Nếu đã bị trừ tiền, KHÔNG '
          'thanh toán lại vì có nguy cơ bị trừ tiền hai lần. Chỉ tiếp tục '
          'khi bạn đã kiểm tra và chắc chắn chưa bị trừ tiền. '
          'Ứng dụng sẽ dùng lại mã giao dịch cũ.',
          'The previous payment is still pending. If you were charged, '
          'DO NOT retry. Only continue after verifying no charge occurred. '
          'The existing payment ID will be reused.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('Quay lại', 'Go back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('Tôi chưa bị trừ tiền', 'I was not charged')),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    // Backend checkout accepts PENDING VNPay payments and returns a new
    // short-lived URL for the *same* payment ID (not a new attempt).
    final checkout = await _repo.checkout(paymentId);
    if (!mounted) return;
    _activeVnpayPaymentId = paymentId;
    await _openCheckoutUrl(checkout);
  }

  Future<void> _checkZaloPayment(
      String paymentId,
      ) async {
    final result =
    await _repo.reconcileZaloPay(paymentId);

    if (!mounted) return;

    setState(() {
      _notice = result['status'] == 'SUCCESS'
          ? tr(
        'Thanh toán thành công.',
        'Payment successful.',
      )
          : tr(
        'Giao dịch chưa được xác nhận thành công.',
        'Payment has not been confirmed.',
      );
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
              error
                  ? Icons.error_outline
                  : Icons.info_outline,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cash.isEmpty)
          _messageCard(
            tr(
              'Chưa có yêu cầu thanh toán tiền mặt.',
              'No cash payment requests yet.',
            ),
          ),
        for (final p in _cash)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    money(p['amount']),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${tr('Trạng thái', 'Status')}: '
                        '${statusText(p['payment_status']?.toString())}',
                  ),
                  if (p['payment_status'] == 'PENDING') ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                            () => _repo.confirmCash(
                          '${p['id']}',
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(
                        tr(
                          'Xác nhận đã nhận tiền',
                          'Confirm Cash Received',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _paymentMethod(
      String code,
      String label,
      IconData icon,
      ) {
    return RadioListTile<String>(
      title: Text(label),
      secondary: Icon(icon),
      value: code,
      groupValue: _method,
      onChanged: _busy
          ? null
          : (value) {
        if (value != null) {
          setState(() => _method = value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking =
        (_data?['booking'] as Map?)
            ?.cast<String, dynamic>() ??
            <String, dynamic>{};

    final payments = _payments();

    final total =
        num.tryParse('${booking['total_amount']}') ?? 0;

    final ready = booking['status'] == 'COMPLETED';

    final confirmed =
        booking['charges_confirmed_at'] != null;

    final paid = payments.any(
          (p) => p['payment_status'] == 'SUCCESS' &&
              (num.tryParse('${p['amount']}') ?? -1) == total,
    );

    final processing = payments.any(
          (p) => ['PENDING', 'PROCESSING']
          .contains(p['payment_status']),
    );
    final cashPending = payments.any((p) =>
        p['method_code'] == 'CASH' &&
        ['PENDING', 'PROCESSING'].contains(p['payment_status']));

    final canPay =
        ready && confirmed && !paid && !processing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.technician
              ? tr(
            'Xác nhận tiền mặt',
            'Cash Confirmation',
          )
              : tr(
            'Thanh toán CoolCare',
            'CoolCare Payment',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: tr('Làm mới', 'Refresh'),
          ),
        ],
      ),
      body: _loading &&
          _data == null &&
          _cash.isEmpty
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const LinearProgressIndicator(),

            if (_error != null)
              _messageCard(
                _error == 'Bad state: AUTH_REQUIRED'
                    ? tr(
                  'Vui lòng đăng nhập.',
                  'Please sign in.',
                )
                    : '${tr('Có lỗi xảy ra', 'An error occurred')}: $_error',
                error: true,
              ),

            if (_notice != null)
              _messageCard(_notice!),

            if (widget.technician)
              _technicianContent()
            else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: paid ? const Color(0xFFE9F7F2) : const Color(0xFFFFF6E3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(paid ? Icons.verified_rounded : Icons.pending_actions_rounded,
                      color: paid ? const Color(0xFF087C65) : const Color(0xFF946500)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(paid ? tr('Đã thanh toán', 'Paid')
                        : processing ? (cashPending ? tr('Chờ kỹ thuật viên xác nhận tiền mặt', 'Awaiting technician cash confirmation') : tr('Chờ xác minh thanh toán', 'Payment verification pending'))
                        : ready ? tr('Chưa thanh toán', 'Unpaid')
                        : tr('Chưa đến bước thanh toán', 'Payment not yet due'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(paid ? tr('Thanh toán đã được xác nhận.', 'Payment confirmed.')
                        : ready ? tr('Công việc đã hoàn thành. Hãy kiểm tra và thanh toán hóa đơn.', 'Service completed. Review and pay the bill.')
                        : tr('Thanh toán sau khi hoàn thành dịch vụ.', 'Pay after service completion.'),
                      style: const TextStyle(fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          'Tổng thanh toán',
                          'Total Payment',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(total),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
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
                      tr(
                        'Thanh toán thành công',
                        'Payment Successful',
                      ),
                    ),
                    subtitle: Text(
                      tr(
                        'Đơn hàng đã được thanh toán.',
                        'The booking has been paid.',
                      ),
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
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'Xác nhận chi phí cuối cùng',
                              'Confirm Final Charges',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
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
                                : () => _run(
                                  () async {
                                await _repo
                                    .confirmCharges(
                                  widget.bookingId,
                                );
                              },
                            ),
                            child: Text(
                              tr(
                                'Xác nhận chi phí',
                                'Confirm Charges',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (processing)
                    _messageCard(
                      tr(
                        'Giao dịch cũ chưa được cổng thanh toán xác nhận kết thúc. '
                            'Hãy kiểm tra lại bên dưới. Khi gateway xác nhận thất bại hoặc hủy, '
                            'bạn có thể chọn bất kỳ phương thức thanh toán nào.',
                        'A payment is pending. '
                            'Check its status below.',
                      ),
                    ),

              if (canPay) ...[
                const SizedBox(height: 16),
                Text(
                  tr(
                    'Chọn phương thức thanh toán',
                    'Choose Payment Method',
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                if (total > 0) ...[
                  _paymentMethod(
                    'CASH',
                    tr('Tiền mặt', 'Cash'),
                    Icons.payments_outlined,
                  ),
                  _paymentMethod(
                    'VNPAY',
                    'VNPay Sandbox',
                    Icons.account_balance_outlined,
                  ),
                  _paymentMethod(
                    'ZALOPAY',
                    'ZaloPay Sandbox',
                    Icons.account_balance_wallet_outlined,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                          () => _pay(total),
                    ),
                    icon: const Icon(
                      Icons.payment,
                    ),
                    label: Text(
                      total == 0
                          ? tr(
                        'Xác nhận miễn phí',
                        'Confirm Free Booking',
                      )
                          : tr(
                        'Thanh toán ngay',
                        'Pay Now',
                      ),
                    ),
                  ),
                ),
              ],

              if (!paid && ready && confirmed)
                for (final p in payments)
                  if (['PENDING', 'PROCESSING']
                      .contains(p['payment_status']) &&
                      ['ZALOPAY', 'VNPAY']
                          .contains(p['method_code']) &&
                      p['id'] != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                              () => _resumeOnlinePayment(
                            '${p['id']}',
                            '${p['method_code']}',
                          ),
                        ),
                        icon: Icon(
                          p['method_code'] == 'ZALOPAY'
                              ? Icons.refresh
                              : Icons.open_in_new,
                        ),
                        label: Text(
                          p['method_code'] == 'ZALOPAY'
                              ? tr(
                            'Kiểm tra thanh toán ZaloPay',
                            'Check ZaloPay Payment',
                          )
                              : tr(
                            'Kiểm tra / thanh toán lại VNPay',
                            'Check / retry VNPay',
                          ),
                        ),
                      ),
                    ),

              if (_activeZaloPaymentId != null &&
                  !paid)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 12,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                          () => _checkZaloPayment(
                        _activeZaloPaymentId!,
                      ),
                    ),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      tr(
                        'Kiểm tra trạng thái ZaloPay',
                        'Verify ZaloPay Status',
                      ),
                    ),
                  ),
                ),

              if (_checkoutUrl != null) ...[
                const SizedBox(height: 16),
                Text(
                  tr(
                    'Liên kết thanh toán VNPay',
                    'VNPay Checkout Link',
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(_checkoutUrl!),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: _checkoutUrl!,
                      ),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(
                            'Đã sao chép liên kết',
                            'Link copied',
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(
                    tr(
                      'Sao chép liên kết',
                      'Copy Link',
                    ),
                  ),
                ),
              ],

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
                label: Text(tr('Xem lịch sử thanh toán', 'View Payment History')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
