import '../../payments/pages/payment_page.dart';
import '../../payments/pages/payment_history_page.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../quotations/pages/quotation_page.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../repositories/booking_detail_repository.dart';
import 'create_booking_page.dart';
import 'recommended_technicians_page.dart';
import '../services/technician_matching_api_service.dart';
import 'booking_vouchers_sheet.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({
    super.key,
    required this.bookingId,
    this.repository,
    this.paymentRepository,
  });
  final String bookingId;
  final BookingDetailRepository? repository;
  final PaymentRepository? paymentRepository;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  static const teal = Color(0xFF078B96);
  late final BookingDetailRepository repo;
  late final PaymentRepository _paymentRepo;
  late Future<Map<String, dynamic>> detail;
  bool cancelling = false;
  bool confirmingCompletion = false;
  bool reportingNoShow = false;
  bool _timelineFailed = false;

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? BookingDetailRepository();
    _paymentRepo = widget.paymentRepository ?? PaymentRepository();
    detail = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final result = await repo.getDetail(widget.bookingId);
    // Keep booking details visible even if the timeline endpoint fails.
    _timelineFailed = false;
    try {
      final timeline = await repo.getTimeline(widget.bookingId);
      result['timeline'] = timeline;
    } catch (_) {
      _timelineFailed = true;
      result['timeline'] ??= <dynamic>[];
    }
    try {
      result['_paymentSummary'] = await _paymentRepo.summary(widget.bookingId);
    } catch (_) {
      result['_paymentSummary'] = null;
    }
    return result;
  }

  void _reload() {
    final next = _load();
    if (!mounted) return;
    setState(() {
      detail = next;
    });
  }

  Future<void> _refresh() async {
    final next = _load();
    if (!mounted) return;
    setState(() {
      detail = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder displays the error. */
    }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }

  String _money(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '');
    if (amount == null) return '—';
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
    );
    return '$formatted đ';
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E8EA)),
          ),
          child: child,
        ),
      ],
    ),
  );

  Widget _info(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: teal),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Future<void> _reportNoShow() async {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final reason = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(vi ? 'Báo kỹ thuật viên không đến' : 'Report technician no-show'),
        content: TextField(
          controller: reason,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(hintText: vi
              ? 'Mô tả thời gian chờ và tình huống (ít nhất 10 ký tự)'
              : 'Describe your wait and what happened (at least 10 characters)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: Text(vi ? 'Đóng' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, reason.text.trim()),
            child: Text(vi ? 'Gửi báo cáo' : 'Submit report')),
        ],
      ),
    );
    reason.dispose();
    if (content == null || !mounted) return;
    if (content.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vi
        ? 'Vui lòng nhập ít nhất 10 ký tự.' : 'Please enter at least 10 characters.')));
      return;
    }
    setState(() => reportingNoShow = true);
    try {
      await repo.reportNoShow(widget.bookingId, content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vi
        ? 'Đã gửi báo cáo để quản trị viên xác minh.'
        : 'Report submitted for admin review.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vi
          ? 'Không gửi được báo cáo hoặc bạn đã báo trước đó.'
          : 'Unable to submit or already reported.')));
      }
    } finally {
      if (mounted) setState(() => reportingNoShow = false);
    }
  }

  Future<void> _removeVoucher() async {
    try {
      await repo.removeVoucher(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        Localizations.localeOf(context).languageCode == 'vi' ? 'Đã gỡ voucher' : 'Voucher removed')));
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        Localizations.localeOf(context).languageCode == 'vi' ? 'Không thể gỡ voucher lúc này' : 'Unable to remove voucher')));
    }
  }

  Future<void> _openVouchers() async {
    final applied = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.72,
          child: BookingVouchersSheet(bookingId: widget.bookingId, repository: repo)),
    );
    if (applied == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('voucherApplied'))));
      _reload();
    }
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CancelReasonDialog(),
    );
    if (reason == null || !mounted) return;
    setState(() {
      cancelling = true;
    });
    try {
      await repo.cancel(widget.bookingId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bookingDetailCancelled'))),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('bookingDetailCancelFailed')}: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cancelling = false;
        });
      }
    }
  }

  Future<void> _rebook(Map<String, dynamic> booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateBookingPage(rebookData: booking),
      ),
    );
  }

  Future<void> _confirmCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('bookingDetailConfirmCompletionTitle')),
        content: Text(context.tr('bookingDetailConfirmCompletionMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('bookingDetailBack')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('bookingDetailConfirmCompletion')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => confirmingCompletion = true);
    try {
      await repo.confirmCompletion(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bookingDetailCompletionConfirmed'))),
      );
      _reload();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentPage(bookingId: widget.bookingId),
        ),
      );
      if (mounted) _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('bookingDetailConfirmCompletionFailed')}: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => confirmingCompletion = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('bookingDetailTitle'))),
    body: FutureBuilder<Map<String, dynamic>>(
      future: detail,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('bookingUiLoadError')),
                  TextButton(
                    onPressed: _reload,
                    child: Text(context.tr('bookingUi60')),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final status = data['status']?.toString() ?? '';
        final paymentSummary = data['_paymentSummary'];
        final paymentRows = paymentSummary is Map && paymentSummary['payments'] is List
            ? paymentSummary['payments'] as List
            : <dynamic>[];
        final paymentPaid = paymentRows.any((p) => p is Map && p['payment_status'] == 'SUCCESS' && (num.tryParse('${p['amount']}') ?? -1) == (num.tryParse('${(paymentSummary is Map ? paymentSummary['booking'] : null) is Map ? (paymentSummary['booking'] as Map)['total_amount'] : null}') ?? -2));
        final awaitingPayment =
            status == 'COMPLETED' &&
                paymentSummary is Map &&
                !paymentPaid;

        final paymentUnknown =
            status == 'COMPLETED' &&
                paymentSummary == null;
        final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
        String bilingual(String vi, String en) => isVietnamese ? vi : en;
        final address = data['address'] is Map
            ? data['address'] as Map
            : <String, dynamic>{};
        final recipient = data['recipient'] is Map
            ? data['recipient'] as Map
            : <String, dynamic>{};
        final pricing = data['pricing'] is Map
            ? data['pricing'] as Map
            : <String, dynamic>{};
        final technician = data['technician'] is Map
            ? data['technician'] as Map
            : null;
        final units = data['units'] is List
            ? data['units'] as List
            : <dynamic>[];
        final timeline = data['timeline'] is List
            ? data['timeline'] as List
            : <dynamic>[];
        final isWaiting = awaitingPayment || paymentUnknown ||
            status == 'PENDING' || status == 'TECHNICIAN_SELECTED';
        final isCancelled = status == 'CANCELLED';
        final statusColor = isCancelled
            ? const Color(0xFFB42318)
            : isWaiting
            ? const Color(0xFF946500)
            : teal;
        final statusBg = isCancelled
            ? const Color(0xFFFEECEB)
            : isWaiting
            ? const Color(0xFFFFF4D8)
            : const Color(0xFFE8F7F5);
        final noteKey = status == 'PENDING'
            ? 'bookingDetailPendingNote'
            : status == 'TECHNICIAN_SELECTED'
            ? 'bookingDetailSelectedNote'
            : status == 'ACCEPTED'
            ? 'bookingDetailAcceptedNote'
            : '';
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
            children: [
              Text(
                data['bookingCode']?.toString() ?? '',
                style: const TextStyle(
                  color: Color(0xFF718087),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(
                      isCancelled
                          ? Icons.cancel_outlined
                          : isWaiting
                          ? Icons.schedule
                          : Icons.check_circle_outline,
                      size: 30,
                      color: statusColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      awaitingPayment
                          ? bilingual('Chưa thanh toán', 'Unpaid')
                          : paymentUnknown
                              ? bilingual('Đang kiểm tra thanh toán', 'Checking payment')
                              : paymentPaid && status == 'COMPLETED'
                                  ? bilingual('Đã thanh toán', 'Paid')
                                  : context.tr('bookingStatus_$status'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (noteKey.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.tr(noteKey),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(
                context.tr('bookingDetailTimeline'),
                _timelineFailed
                    ? Column(children: [
                  Text(context.tr('bookingDetailTimelineLoadFailed')),
                  TextButton(onPressed: _reload, child: Text(context.tr('bookingUi60'))),
                ])
                    : timeline.isEmpty
                    ? Text(context.tr('bookingDetailNoTimeline'))
                    : Column(
                  children: [
                    for (var i = 0; i < timeline.length; i++)
                      if (timeline[i] is Map)
                        _timelineRow(
                          timeline[i] as Map,
                          i == timeline.length - 1,
                        ),
                  ],
                ),
              ),
              if (technician != null)
                _section(
                  context.tr('bookingUiTechnician'),
                  _info(
                    Icons.engineering_outlined,
                    technician['name']?.toString() ?? '—',
                  ),
                ),
              _section(
                context.tr('bookingUi42'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final raw in units)
                      if (raw is Map) ...[
                        Text(
                          '${context.tr('bookingUiUnit')} ${raw['unit_number'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (raw['brand_name'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${raw['brand_name']} ${raw['model_name'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718087),
                              ),
                            ),
                          ),
                        if (raw['services'] is List)
                          for (final service in raw['services'] as List)
                            if (service is Map)
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service['name']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _money(service['unitPrice']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                        if ((raw['description']?.toString() ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(
                              raw['description'].toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
              _section(
                context.tr('bookingDetailAddressSchedule'),
                Column(
                  children: [
                    _info(
                      Icons.location_on_outlined,
                      [address['addressLine'], address['ward'], address['city']]
                          .where(
                            (part) => part != null && '$part'.trim().isNotEmpty,
                      )
                          .join(', '),
                    ),
                    _info(
                      Icons.calendar_today_outlined,
                      _date(data['scheduledAt']),
                    ),
                    _info(
                      Icons.person_outline,
                      '${recipient['name'] ?? ''} · ${recipient['phone'] ?? ''}',
                    ),
                  ],
                ),
              ),
              _section(
                context.tr('bookingUi45'),
                Column(children: [
                  if ((num.tryParse('${pricing['discountAmount']}') ?? 0) > 0) ...[
                    Row(children: [Expanded(child: Text(context.tr('voucherDiscount'))), Text('-${_money(pricing['discountAmount'])}'), if (status == 'QUOTATION_ACCEPTED' || status == 'WAITING_CONFIRMATION') IconButton(tooltip: bilingual('Gỡ voucher', 'Remove voucher'), onPressed: _removeVoucher, icon: const Icon(Icons.close_rounded))]),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(child: Text(context.tr('bookingUiTotal'))),
                      Text(
                        _money(pricing['totalAmount']),
                        style: const TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                      QuotationPage(bookingId: widget.bookingId, technician: false)));
                  if (mounted) _reload();
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(Localizations.localeOf(context).languageCode == 'vi'
                    ? 'Xem / phản hồi báo giá' : 'View / Respond to Quotation'),
              )),
              if (status == 'ACCEPTED' &&
                  (DateTime.tryParse('${data['scheduledAt'] ?? ''}')?.toLocal()
                    .add(const Duration(minutes: 30))
                    .isBefore(DateTime.now()) ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: reportingNoShow ? null : _reportNoShow,
                    icon: const Icon(Icons.report_problem_outlined),
                    label: Text(bilingual('Báo KTV không đến', 'Report technician no-show')),
                  ),
                ),
              if (status == 'PENDING' && technician == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: () async {
                      final matching = TechnicianMatchingApiService();
                      await Navigator.of(context).push(
                        MaterialPageRoute<RecommendedTechnician>(
                          builder: (_) => RecommendedTechniciansPage(
                            bookingId: widget.bookingId,
                            loadRecommendations: matching.getRecommendedTechnicians,
                            sendRequest: matching.selectTechnician,
                          ),
                        ),
                      );
                      if (mounted) _reload();
                    },
                    icon: const Icon(Icons.engineering_outlined),
                    label: Text(bilingual('Tiếp tục chọn kỹ thuật viên', 'Choose a technician')),
                  ),
                ),
              if (status == 'COMPLETED') Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: paymentUnknown
                    ? OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(bilingual('Kiểm tra lại thanh toán', 'Retry payment check')),
                      )
                    : awaitingPayment
                    ? FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaymentPage(bookingId: widget.bookingId),
                      ),
                    );
                    if (mounted) _reload();
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(bilingual('Xem trạng thái thanh toán', 'View Payment Status')),
                )
                    : OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaymentHistoryPage(bookingId: widget.bookingId),
                      ),
                    );
                    if (mounted) _reload();
                  },
                  icon: const Icon(Icons.history),
                  label: Text(bilingual('Lịch sử thanh toán', 'Payment History')),
                ),
              ),
              if (status == 'QUOTATION_ACCEPTED' || status == 'WAITING_CONFIRMATION')
                Padding(padding: const EdgeInsets.only(bottom: 12), child: OutlinedButton.icon(
                  onPressed: _openVouchers, icon: const Icon(Icons.local_offer_outlined),
                  label: Text(context.tr('voucherTitle')),
                )),
              if ((data['cancellationReason']?.toString() ?? '').isNotEmpty)
                _section(
                  context.tr('bookingDetailReason'),
                  Text(data['cancellationReason'].toString()),
                ),
              if (data['canCancel'] == true)
                OutlinedButton.icon(
                  onPressed: cancelling ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(context.tr('bookingDetailCancel')),
                ),
              if (data['canConfirmCompletion'] == true || status == 'WAITING_CONFIRMATION')
                FilledButton.icon(
                  onPressed: confirmingCompletion ? null : _confirmCompletion,
                  icon: confirmingCompletion
                      ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.task_alt_rounded),
                  label: Text(context.tr('bookingDetailConfirmCompletion')),
                ),
              if (isCancelled)
                FilledButton.icon(
                  onPressed: () => _rebook(data),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('bookingDetailRebook')),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _timelineRow(Map item, bool last) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, size: 19, color: teal),
            if (!last)
              Container(width: 2, height: 24, color: const Color(0xFFD9E8EA)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('bookingStatus_${item['status']}'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _date(item['created_at'] ?? item['createdAt']),
                style: const TextStyle(fontSize: 11, color: Color(0xFF718087)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('bookingDetailCancelTitle')),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLines: 3,
      maxLength: 1000,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(hintText: context.tr('bookingDetailReason')),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('bookingDetailBack')),
      ),
      FilledButton(
        onPressed: controller.text.trim().length < 5
            ? null
            : () => Navigator.of(context).pop(controller.text.trim()),
        child: Text(context.tr('bookingDetailConfirmCancel')),
      ),
    ],
  );
}
