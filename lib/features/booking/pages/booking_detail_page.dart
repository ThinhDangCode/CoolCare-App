import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../repositories/booking_detail_repository.dart';
import 'create_booking_page.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({
    super.key,
    required this.bookingId,
    this.repository,
  });
  final String bookingId;
  final BookingDetailRepository? repository;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  static const teal = Color(0xFF078B96);
  late final BookingDetailRepository repo;
  late Future<Map<String, dynamic>> detail;
  bool cancelling = false;
  bool confirmingCompletion = false;

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? BookingDetailRepository();
    detail = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final result = await repo.getDetail(widget.bookingId);
    // Timeline is a separate endpoint; do not depend on it to display details.
    try {
      final timeline = await repo.getTimeline(widget.bookingId);
      result['timeline'] = timeline;
    } catch (_) {
      result['timeline'] ??= <dynamic>[];
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
      Navigator.of(context).pop(true);
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
      Navigator.of(context).pop(true);
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
        final isWaiting =
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
                      context.tr('bookingStatus_$status'),
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
                timeline.isEmpty
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
              ),
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
              if (data['canConfirmCompletion'] == true)
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
                  label: Text(context.tr('bookingRebook')),
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
