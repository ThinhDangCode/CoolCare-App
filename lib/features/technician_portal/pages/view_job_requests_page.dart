import 'package:flutter/material.dart';
import '../../payments/repositories/payment_repository.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/service_text.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/view_job_request.dart';
import '../repositories/technician_portal_repository.dart';
import 'view_job_request_detail_page.dart';

class ViewJobRequestsPage extends StatefulWidget {
  const ViewJobRequestsPage({
    required this.repository,
    required this.onRequestChanged,
    super.key,
  });

  final TechnicianPortalRepository repository;
  final Future<void> Function() onRequestChanged;

  @override
  State<ViewJobRequestsPage> createState() => _ViewJobRequestsPageState();
}

class _ViewJobRequestsPageState extends State<ViewJobRequestsPage> {
  int _tab = 0;
  late Future<List<ViewJobRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = _fetch();
  }

  Future<List<ViewJobRequest>> _fetch() async {
    final status = switch (_tab) {
      0 => 'SELECTED',
      1 => 'ACCEPTED',
      2 => 'COMPLETED',
      _ => 'CLOSED',
    };
    return widget.repository.viewJobRequests(status: status);
  }

  void _selectTab(int value) {
    if (_tab == value) return;
    setState(() {
      _tab = value;
      _requests = _fetch();
    });
  }

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => _requests = next);
    await next;
  }

  void _retry() => setState(() => _requests = _fetch());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Text(
            context.tr('jobs'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FutureBuilder<List<ViewJobRequest>>(
          future: _requests,
          builder: (context, snapshot) => _ViewJobRequestsTabs(
            selected: _tab,
            newCount: _tab == 0 && snapshot.hasData
                ? snapshot.data!.length
                : null,
            onSelected: _selectTab,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ViewJobRequest>>(
            future: _requests,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                final message = error is ApiException
                    ? error.message
                    : context.tr('unableLoadJobRequests');
                return _ViewJobRequestsMessage(
                  icon: Icons.cloud_off_outlined,
                  message: message,
                  actionLabel: context.tr('tryAgain'),
                  onAction: _retry,
                );
              }
              final items = snapshot.data ?? const <ViewJobRequest>[];
              if (items.isEmpty) {
                return _ViewJobRequestsMessage(
                  icon: Icons.assignment_turned_in_outlined,
                  message: switch (_tab) {
                    0 => context.tr('noNewJobRequests'),
                    1 => context.tr('noOngoingJobs'),
                    2 => Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa có công việc hoàn thành' : 'No completed jobs yet',
                    _ => Localizations.localeOf(context).languageCode == 'vi' ? 'Chưa có công việc đã đóng' : 'No closed jobs yet',
                  },
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _ViewJobRequestCard(
                    request: items[index],
                    onView: () => _showDetails(items[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showDetails(ViewJobRequest request) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ViewJobRequestDetailPage(
          request: request,
          repository: widget.repository,
        ),
      ),
    );
    if (changed == true && mounted) {
      await Future.wait([_refresh(), widget.onRequestChanged()]);
    }
  }
}

class _ViewJobRequestsTabs extends StatelessWidget {
  const _ViewJobRequestsTabs({
    required this.selected,
    required this.onSelected,
    this.newCount,
  });

  final int selected;
  final int? newCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        _tab(context, context.tr('newRequests'), 0, count: newCount),
        _tab(context, context.tr('ongoing'), 1),
        _tab(context, context.tr('statusCompleted'), 2),
        _tab(context, Localizations.localeOf(context).languageCode == 'vi' ? 'Đã đóng' : 'Closed', 3),
      ],
    ),
  );

  Widget _tab(BuildContext context, String label, int value, {int? count}) {
    final active = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(value),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? CoolCareColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CoolCareColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),
            Container(
              height: 2,
              color: active ? CoolCareColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewJobRequestCard extends StatefulWidget {
  const _ViewJobRequestCard({required this.request, required this.onView});

  final ViewJobRequest request;
  final VoidCallback onView;

  @override
  State<_ViewJobRequestCard> createState() => _ViewJobRequestCardState();
}

class _ViewJobRequestCardState extends State<_ViewJobRequestCard> {
  Future<String>? _paymentStatus;

  @override
  void initState() {
    super.initState();
    if (widget.request.status == 'COMPLETED') {
      _paymentStatus = _fetchPaymentStatus();
    }
  }

  @override
  void didUpdateWidget(covariant _ViewJobRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.booking.id != oldWidget.request.booking.id ||
        widget.request.status != oldWidget.request.status) {
      _paymentStatus = widget.request.status == 'COMPLETED'
          ? _fetchPaymentStatus()
          : null;
    }
  }

  Future<String> _fetchPaymentStatus() async {
    final result = await PaymentRepository().technicianSummary(
      widget.request.booking.id,
    );
    final rows = (result['payments'] as List? ?? []).whereType<Map>();
    if (rows.any((p) => p['payment_status'] == 'SUCCESS')) return 'Paid';
    if (rows.any(
      (p) =>
          p['payment_status'] == 'PENDING' ||
          p['payment_status'] == 'PROCESSING',
    )) {
      return 'Pending payment';
    }
    return 'Unpaid';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.request.booking;
    final isNew = widget.request.status == 'SELECTED';
    final isHistory = const {
      'DECLINED',
      'EXPIRED',
      'COMPLETED',
      'CANCELLED',
    }.contains(widget.request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.ac_unit_rounded,
                  size: 16,
                  color: CoolCareColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizedServiceName(context, booking.primaryServiceName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ViewJobRequestStatus(
                status: widget.request.status,
                isNew: isNew,
              ),
            ],
          ),
          if (widget.request.status == 'COMPLETED') ...[
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _paymentStatus,
              builder: (context, snapshot) {
                final label = snapshot.hasError
                    ? (Localizations.localeOf(context).languageCode == 'vi'
                        ? 'Không tải được thanh toán' : 'Payment unavailable')
                    : snapshot.hasData
                    ? (Localizations.localeOf(context).languageCode == 'vi'
                        ? (snapshot.data! == 'Paid' ? 'Đã thanh toán'
                            : snapshot.data! == 'Pending' ? 'Đang xử lý'
                            : 'Chưa thanh toán') : snapshot.data!)
                    : (Localizations.localeOf(context).languageCode == 'vi'
                        ? 'Đang kiểm tra thanh toán...' : 'Checking payment...');
                final paid = label == 'Paid' || label == 'Đã thanh toán';
                return Row(
                  children: [
                    Icon(
                      paid ? Icons.verified_rounded : Icons.payments_outlined,
                      size: 16,
                      color: paid
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: paid
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _line(
            context,
            isHistory ? Icons.history_rounded : Icons.calendar_today_outlined,
            _date(
              context,
              isHistory ? widget.request.historyAt : booking.scheduledAt,
            ),
          ),
          const SizedBox(height: 6),
          _line(context, Icons.location_on_outlined, booking.address),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('bookingTotal'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _money(booking.totalAmount),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.tr('estimatedEarnings'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _money(booking.totalAmount * .8),
                      style: const TextStyle(
                        color: CoolCareColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: widget.onView,
                  style: FilledButton.styleFrom(
                    backgroundColor: CoolCareColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    context.tr('view'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 15, color: CoolCareColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text.isEmpty ? context.tr('jobNotProvided') : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}

class _ViewJobRequestStatus extends StatelessWidget {
  const _ViewJobRequestStatus({required this.status, required this.isNew});
  final String status;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final color = isNew ? const Color(0xFFDC2626) : CoolCareColors.primary;
    final background = isNew
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFEAF6F7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isNew ? context.tr('newRequest') : _statusLabel(context, status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ViewJobRequestsMessage extends StatelessWidget {
  const _ViewJobRequestsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 110),
      Icon(icon, size: 44, color: const Color(0xFF8AA0A6)),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      if (onAction != null) ...[
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ),
      ],
    ],
  );
}

String _date(BuildContext context, DateTime? value) {
  if (value == null) return context.tr('jobNotScheduled');
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} - ${two(local.hour)}:${two(local.minute)}';
}

String _money(double value) {
  final formatted = value.round().toString().replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+$)'),
    (_) => ',',
  );
  return '$formatted VND';
}

String _statusLabel(BuildContext context, String status) => switch (status) {
  'ACCEPTED' => context.tr('statusOngoing'),
  'DECLINED' => context.tr('statusDeclined'),
  'EXPIRED' => context.tr('statusExpired'),
  'COMPLETED' => context.tr('statusCompleted'),
  'CANCELLED' => context.tr('statusCancelled'),
  _ => status,
};
