import 'dart:io' show FileSystemException;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization/service_text.dart';
import '../../../core/network/api_exception.dart';
import '../models/payment_invoice.dart';
import '../repositories/payment_repository.dart';
import '../services/invoice_file_saver.dart';

// Palette sampled from the invoice design (Figma).
const _orange = Color(0xFFFF6B00);
const _orangeSoft = Color(0xFFFFF1E5);
const _orangeLine = Color(0xFFFFD2B2);
const _ink = Color(0xFF0F172A);
const _line = Color(0xFFDCE1E7);
const _tableHead = Color(0xFFF3F4F6);
const _muted = Color(0xFF64748B);

/// Payment details + invoice (view, download as PDF, send to email).
class PaymentInvoicePage extends StatefulWidget {
  const PaymentInvoicePage({super.key, required this.payment, this.repository});

  /// Row from the payment history list (`id`, `payment_status`, ...).
  final Map<String, dynamic> payment;
  final PaymentRepository? repository;

  @override
  State<PaymentInvoicePage> createState() => _PaymentInvoicePageState();
}

class _PaymentInvoicePageState extends State<PaymentInvoicePage> {
  late final PaymentRepository _repo = widget.repository ?? PaymentRepository();
  Future<PaymentInvoice>? _future;
  bool _downloading = false;

  String get _paymentId => '${widget.payment['id'] ?? ''}';

  bool get _paid {
    final value = '${widget.payment['payment_status']}'.toUpperCase();
    return value == '2' || value == 'SUCCESS';
  }

  @override
  void initState() {
    super.initState();
    if (_paid) _load();
  }

  void _load() {
    _future = _repo.invoice(_paymentId).then(PaymentInvoice.fromJson);
  }

  String _t(String vi, String en) =>
      Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

  String _invoiceLabel(String value) {
    if (Localizations.localeOf(context).languageCode == 'vi') return value;
    return const {
          'Đã thanh toán': 'Paid',
          'Chờ thanh toán': 'Pending payment',
          'Đang xử lý': 'Processing',
          'Thất bại': 'Failed',
          'Đã hủy': 'Cancelled',
          'Không xác định': 'Unknown',
          'Tiền mặt': 'Cash',
          'Miễn phí': 'Free',
        }[value] ?? value;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      switch (error.code) {
      }
      return error.message;
    }
    if (error is StateError && error.message == 'AUTH_REQUIRED') {
      return _t('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          'Your session has expired. Please sign in again.');
    }
    return _t('Đã có lỗi xảy ra. Vui lòng thử lại.',
        'Something went wrong. Please try again.');
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ));
  }

  Future<void> _download(PaymentInvoice invoice) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final file = await _repo.downloadInvoicePdf(_paymentId);
      final name = file.fileName ?? 'HoaDon-${invoice.invoiceNumber}.pdf';
      await saveAndOpenInvoicePdf(bytes: file.bytes, fileName: name);
    } on FileSystemException catch (error) {
      _toast(error.message, error: true);
    } catch (error) {
      _toast(_errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ---- formatting -------------------------------------------------------

  String _digits(num value) {
    final n = value.round();
    final text = n.abs().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return n < 0 ? '-$text' : text;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _date(DateTime? d) =>
      d == null ? '—' : '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String _dateTime(DateTime? d) =>
      d == null ? '—' : '${_date(d)} · ${_two(d.hour)}:${_two(d.minute)}';

  String _quantity(num q) => q == q.roundToDouble() ? '${q.round()}' : '$q';

  Widget _money(num value,
      {double size = 14, FontWeight weight = FontWeight.w600, Color color = _ink}) {
    final style = TextStyle(fontSize: size, fontWeight: weight, color: color);
    return Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: '${_digits(value)} '),
        TextSpan(
            text: _t('đ', 'VND'),
            style: const TextStyle(decoration: TextDecoration.underline)),
      ]),
      textAlign: TextAlign.end,
    );
  }

  // ---- building blocks --------------------------------------------------

  Widget _section(String title, Widget child, {EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: _orangeSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(title,
              style: const TextStyle(
                  color: _orange, fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _bar(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _orangeSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _orangeLine),
        ),
        child: Text(title,
            style: const TextStyle(
                color: _orange, fontWeight: FontWeight.w800, fontSize: 15)),
      );

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: _muted)),
          TextSpan(text: value),
        ]), style: const TextStyle(fontSize: 14, color: _ink, height: 1.35)),
      );

  Widget _header(PaymentInvoice invoice, bool wide) {
    final logo = Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(painter: _LogoPainter())),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CoolCare',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, color: _ink, height: 1)),
        const SizedBox(height: 4),
        Text(_t('DỊCH VỤ ĐIỆN LẠNH', 'AIR CONDITIONING SERVICES'),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: _ink)),
      ]),
    ]);
    final meta = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(_t('HÓA ĐƠN DỊCH VỤ', 'SERVICE INVOICE'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        SelectableText(
            '${_t('Số hóa đơn', 'Invoice no.')}: ${invoice.invoiceNumber}',
            style: const TextStyle(fontSize: 13, color: _ink)),
        Text('${_t('Ngày lập', 'Issued')}: ${_date(invoice.issuedAt)}',
            style: const TextStyle(fontSize: 13, color: _ink)),
      ],
    );
    return wide
        ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [logo, meta])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            logo,
            const SizedBox(height: 16),
            meta,
          ]);
  }

  Widget _infoBar(PaymentInvoice invoice, bool wide) {
    final cells = [
      '${_t('Mã booking', 'Booking')}: ${invoice.bookingCode}',
      '${_t('Ngày dịch vụ', 'Service date')}: ${_date(invoice.serviceDate)}',
      '${_t('Kỹ thuật viên', 'Technician')}: ${invoice.technicianName ?? '—'}',
    ];
    Widget cell(String text) => Text(text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _ink));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _orangeLine),
      ),
      child: wide
          ? IntrinsicHeight(
              child: Row(children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0)
                    const VerticalDivider(color: _orange, width: 32, thickness: 1.5),
                  Expanded(child: cell(cells[i])),
                ],
              ]),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                cell(cells[i]),
              ],
            ]),
    );
  }

  Widget _servicesTable(PaymentInvoice invoice) {
    Widget head(String text, {TextAlign align = TextAlign.center}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(text,
              textAlign: align,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _ink)),
        );
    Widget pad(Widget child, {Alignment alignment = Alignment.centerLeft}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Align(alignment: alignment, child: child),
        );
    if (invoice.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: _line), borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Text(_t('Chưa có hạng mục dịch vụ.', 'No service items.'),
            style: const TextStyle(color: _muted)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3.2),
          1: FlexColumnWidth(0.9),
          2: FlexColumnWidth(2.1),
          3: FlexColumnWidth(2.3),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder.symmetric(
            inside: BorderSide(color: _line, width: 1)),
        children: [
          TableRow(decoration: const BoxDecoration(color: _tableHead), children: [
            head(_t('Nội dung', 'Item'), align: TextAlign.start),
            head(_t('SL', 'Qty')),
            head(_t('Đơn giá', 'Price')),
            head(_t('Thành tiền', 'Amount')),
          ]),
          for (final item in invoice.items)
            TableRow(children: [
              pad(Text(localizedServiceName(context, item.description),
                  style: const TextStyle(fontSize: 13.5, color: _ink, height: 1.3))),
              pad(Text(_quantity(item.quantity),
                  style: const TextStyle(fontSize: 13.5, color: _ink)),
                  alignment: Alignment.center),
              pad(_money(item.unitPrice, size: 13, weight: FontWeight.w500),
                  alignment: Alignment.centerRight),
              pad(_money(item.totalPrice, size: 13, weight: FontWeight.w600),
                  alignment: Alignment.centerRight),
            ]),
        ],
      ),
    );
  }

  Widget _materials(PaymentInvoice invoice) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line)),
        child: Row(children: [
          Expanded(
              child: Text(_t('Tổng tiền vật tư', 'Materials total'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: _ink))),
          _money(invoice.partsAmount, size: 14.5, weight: FontWeight.w800),
        ]),
      );

  Widget _totals(PaymentInvoice invoice) {
    Widget row(String label, num value, {bool top = true}) => Container(
          decoration: BoxDecoration(
              border: top ? const Border(top: BorderSide(color: _line)) : null),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: _ink))),
            _money(value, size: 14.5, weight: FontWeight.w800),
          ]),
        );
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        row(_t('Tạm tính', 'Subtotal'), invoice.subtotal, top: false),
        row(_t('Giảm giá', 'Discount'),
            invoice.discountAmount > 0 ? -invoice.discountAmount : 0),
        Container(
          color: _orangeSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(children: [
            Expanded(
                child: Text(_t('TỔNG THANH TOÁN', 'TOTAL'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17, color: _orange))),
            _money(invoice.totalAmount, size: 22, weight: FontWeight.w900, color: _orange),
          ]),
        ),
        row(_t('Đã thanh toán', 'Paid'), invoice.paidAmount),
        row(_t('Còn phải trả', 'Balance due'), invoice.remainingAmount),
      ]),
    );
  }

  Widget _providerCard(PaymentInvoice invoice) => _section(
        _t('ĐƠN VỊ CUNG CẤP', 'PROVIDER'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(invoice.providerName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          _kv(_t('Địa chỉ', 'Address'),
              invoice.providerAddress ?? _t('[Địa chỉ doanh nghiệp]', '[Business address]')),
          _kv('Hotline', invoice.providerHotline ?? _t('[Số hỗ trợ]', '[Support number]')),
          if ((invoice.providerTaxCode ?? '').isNotEmpty)
            _kv(_t('MST', 'Tax code'), invoice.providerTaxCode!),
          if (!invoice.providerConfigured)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_t('Thông tin chờ cấu hình', 'Details pending configuration'),
                    style: const TextStyle(fontSize: 14, color: _ink))),
        ]),
      );

  Widget _customerCard(PaymentInvoice invoice) => _section(
        _t('KHÁCH HÀNG', 'CUSTOMER'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(invoice.customerName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          _kv(_t('Điện thoại', 'Phone'), invoice.customerPhone),
          _kv(_t('Địa chỉ thực hiện', 'Service address'),
              invoice.customerAddress.isEmpty ? '—' : invoice.customerAddress),
        ]),
      );

  Widget _paymentCard(PaymentInvoice invoice) => _section(
        _t('THÔNG TIN THANH TOÁN', 'PAYMENT'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kv(_t('Trạng thái', 'Status'), _invoiceLabel(invoice.statusLabel)),
          _kv(_t('Phương thức', 'Method'), _invoiceLabel(invoice.methodLabel)),
          _kv(_t('Thời gian', 'Time'), _dateTime(invoice.paidAt)),
        ]),
      );

  Widget _notesCard(PaymentInvoice invoice) => _section(
        _t('GHI CHÚ', 'NOTES'),
        Text(invoice.notes.isEmpty ? _t('Không có ghi chú.', 'No notes.') : invoice.notes,
            style: const TextStyle(fontSize: 13.5, color: _ink, height: 1.4)),
      );

  Widget _invoiceBody(PaymentInvoice invoice, double width) {
    final wide = width >= 720;
    const gap = SizedBox(height: 16);
    final money = <Widget>[
      _bar(_t('DỊCH VỤ VÀ TIỀN CÔNG', 'SERVICES AND LABOR')),
      const SizedBox(height: 12),
      _servicesTable(invoice),
      gap,
      _bar(_t('VẬT TƯ', 'MATERIALS')),
      const SizedBox(height: 12),
      _materials(invoice),
      gap,
      _totals(invoice),
    ];
    final info = <Widget>[
      _providerCard(invoice),
      gap,
      _customerCard(invoice),
      gap,
      _paymentCard(invoice),
      gap,
      _notesCard(invoice),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(invoice, wide),
      const SizedBox(height: 20),
      _infoBar(invoice, wide),
      const SizedBox(height: 20),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 4, child: Column(children: info)),
          const SizedBox(width: 20),
          Expanded(flex: 7, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: money)),
        ])
      else ...[
        // On phones the amounts come first, supporting details after.
        ...money,
        gap,
        _paymentCard(invoice),
        gap,
        _customerCard(invoice),
        gap,
        _providerCard(invoice),
        gap,
        _notesCard(invoice),
      ],
    ]);
  }

  // ---- states -----------------------------------------------------------

  Widget _state({required IconData icon, required String title, String? detail, Widget? action}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: _muted),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action],
        ]),
      ),
    );
  }

  Widget _paymentSummary() {
    final p = widget.payment;
    return _section(
      _t('THÔNG TIN GIAO DỊCH', 'TRANSACTION'),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ('${p['payment_code'] ?? ''}'.isNotEmpty) _kv(_t('Mã giao dịch', 'Payment code'), '${p['payment_code']}'),
        _kv(_t('Số tiền', 'Amount'),
            '${_digits(num.tryParse('${p['amount']}') ?? 0)} ${_t('đ', 'VND')}'),
      ]),
    );
  }

  Widget _unavailable({required String title, required String detail}) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
              height: 280,
              child: _state(icon: Icons.receipt_long_outlined, title: title, detail: detail)),
          _paymentSummary(),
        ],
      );

  Widget _loading() => const Center(child: CircularProgressIndicator(color: _orange));

  @override
  Widget build(BuildContext context) {
    final invoiceFuture = _future;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(_t('Chi tiết hóa đơn', 'Invoice details'))),
      body: !_paid
          ? _unavailable(
              title: _t('Chưa có hóa đơn', 'No invoice yet'),
              detail: _t('Hóa đơn chỉ khả dụng sau khi giao dịch thanh toán thành công.',
                  'The invoice is available once the payment succeeds.'))
          : FutureBuilder<PaymentInvoice>(
              future: invoiceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return _loading();
                final error = snapshot.error;
                if (error != null) {
                  if (error is ApiException && error.code == 'INVOICE_NOT_FOUND') {
                    return _unavailable(
                        title: _t('Hóa đơn chưa được phát hành', 'Invoice not issued yet'),
                        detail: _t('Hệ thống sẽ gửi hóa đơn qua email ngay khi được phát hành.',
                            'We will email the invoice as soon as it is issued.'));
                  }
                  if (error is ApiException && error.code == 'INVOICE_NOT_AVAILABLE') {
                    return _unavailable(
                        title: _t('Chưa có hóa đơn', 'No invoice yet'),
                        detail: error.message);
                  }
                  return _state(
                    icon: Icons.wifi_off_rounded,
                    title: _t('Không thể tải hóa đơn', 'Unable to load invoice'),
                    detail: _errorMessage(error),
                    action: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _orange),
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: Text(_t('Thử lại', 'Retry')),
                    ),
                  );
                }
                final invoice = snapshot.requireData;
                return Column(children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: _orange,
                      onRefresh: () async {
                        setState(_load);
                        try {
                          await _future;
                        } catch (_) {}
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: _invoiceBody(invoice, constraints.maxWidth),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _actions(invoice),
                ]);
              },
            ),
    );
  }

  Widget _actions(PaymentInvoice invoice) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: _orange, minimumSize: const Size.fromHeight(48)),
                onPressed: _downloading ? null : () => _download(invoice),
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_outlined),
                label: Text(_t('Tải hóa đơn (PDF)', 'Download invoice (PDF)')),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Hóa đơn cũng được tự động gửi tới ${invoice.customerEmail} sau khi dịch vụ hoàn thành.',
                  'The invoice is also emailed to ${invoice.customerEmail} automatically once the service is completed.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: _muted),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * 0.2)),
      Paint()..color = _orange,
    );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.057
      ..strokeCap = StrokeCap.round;
    final center = Offset(s / 2, s / 2);
    final arm = s * 0.34;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center, center + dir * arm, paint);
      final branchStart = center + dir * arm * 0.62;
      for (final side in [-1, 1]) {
        final a = angle + side * math.pi / 4;
        canvas.drawLine(branchStart,
            branchStart + Offset(math.cos(a), math.sin(a)) * arm * 0.34, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
