import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/booking_detail_repository.dart';

class BookingTravelStatus extends StatefulWidget {
  const BookingTravelStatus({super.key, required this.bookingId, required this.repository});
  final String bookingId;
  final BookingDetailRepository repository;
  @override
  State<BookingTravelStatus> createState() => _BookingTravelStatusState();
}

class _BookingTravelStatusState extends State<BookingTravelStatus> {
  Map<String, dynamic>? data;
  bool error = false;
  bool approving = false;
  bool loading = false;
  String? approvalError;
  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }
  @override
  void dispose() { _refreshTimer?.cancel(); super.dispose(); }
  Future<void> _load() async {
    if (loading) return;
    loading = true;
    try {
      final value = await widget.repository.travelStatus(widget.bookingId);
      if (mounted) setState(() { data = value; error = false; approvalError = null; });
    } catch (_) { if (mounted) setState(() => error = true); }
    finally { loading = false; }
  }
  Future<void> _approveEarly() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cho phép bắt đầu sửa sớm?'),
      content: const Text('Thợ đã xác nhận đến nơi. Bạn đồng ý để thợ bắt đầu sửa chữa trước giờ hẹn?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Chưa đồng ý')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý bắt đầu sớm')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    final appointment = DateTime.tryParse('${data?['scheduled_at'] ?? ''}')?.toLocal();
    if (appointment != null && !DateTime.now().isBefore(appointment.subtract(const Duration(minutes: 15)))) {
      await _load();
      return;
    }
    setState(() { approving = true; approvalError = null; });
    try {
      final result = await widget.repository.approveEarlyStart(widget.bookingId);
      if (mounted) setState(() => data = result);
      await _load();
    } catch (e) {
      if (mounted) setState(() => approvalError = 'Không xác nhận được: $e');
    } finally { if (mounted) setState(() => approving = false); }
  }
  String format(dynamic raw) {
    final dt = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (dt == null) return 'Chưa có';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
      ' ${dt.day}/${dt.month}';
  }
  @override
  Widget build(BuildContext context) {
    final phase = data?['status']?.toString() ?? 'NOT_STARTED';
    final scheduled = DateTime.tryParse('${data?['scheduled_at'] ?? ''}')?.toLocal();
    final beforeAppointment = scheduled != null && DateTime.now().isBefore(scheduled);
    final needsEarlyConsent = scheduled != null &&
        DateTime.now().isBefore(scheduled.subtract(const Duration(minutes: 15)));
    final arrived = phase == 'ARRIVED';
    final approved = data?['early_start_approved'] == true;
    final earlyArrival = data?['early_arrival'] == true;
    final needsApproval = arrived && earlyArrival && !approved && needsEarlyConsent;
    final colorScheme = Theme.of(context).colorScheme;
    final late = arrived && data?['arrival_late'] == true;
    final title = phase == 'ARRIVED' ? 'Thợ đã đến nơi'
        : phase == 'TRAVELLING' ? 'Thợ đang di chuyển' : 'Chưa bắt đầu di chuyển';
    final leadingIcon = arrived ? Icons.check_circle_outline
        : phase == 'TRAVELLING' ? Icons.directions_car_outlined : Icons.schedule_outlined;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TRẠNG THÁI DI CHUYỂN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: 0.7,
                  color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(leadingIcon, color: late ? colorScheme.error : colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(error ? 'Chưa cập nhật được hành trình'
                  : arrived ? 'Xác nhận lúc ${format(data?['arrived_at'])}'
                  : phase == 'TRAVELLING' ? 'Dự kiến đến: ${format(data?['eta_at'])}'
                  : 'Đang chờ thợ bắt đầu hành trình',
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
          if (scheduled != null) ...[
            const SizedBox(height: 10),
            Text('Giờ hẹn: ${format(data?['scheduled_at'])}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (data?['arrival_late'] == true && !arrived) ...[
            const SizedBox(height: 10),
            Text('Đã quá giờ hẹn hơn 15 phút, thợ chưa xác nhận đến nơi.',
                style: TextStyle(color: colorScheme.error)),
          ],
          if (arrived && earlyArrival) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(approved ? 'Đã đồng ý bắt đầu sớm'
                    : needsEarlyConsent ? 'Thợ đến sớm hơn 15 phút'
                    : 'Có thể bắt đầu không cần xác nhận',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(approved
                    ? 'Thợ có thể tiếp tục công việc theo quy trình bình thường.'
                    : needsEarlyConsent
                        ? 'Bạn có thể cho phép thợ bắt đầu ngay hoặc chờ đến khi còn 15 phút trước giờ hẹn.'
                        : 'Trong khoảng 15 phút trước giờ hẹn hoặc muộn hơn, thợ có thể bắt đầu mà không cần xác nhận thêm.'),
              ]),
            ),
            if (needsApproval) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: approving ? null : _approveEarly,
                icon: approving ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Đồng ý cho thợ bắt đầu sớm'),
              )),
            ],
          ],
          if (approvalError != null) ...[
            const SizedBox(height: 8),
            Text(approvalError!, style: TextStyle(color: colorScheme.error)),
          ],
          if (late) ...[
            const SizedBox(height: 10),
            Text('Thợ đến trễ ${data?['arrival_late_minutes'] ?? 15} phút so với giờ hẹn.',
                style: TextStyle(color: colorScheme.error)),
          ],
          if (arrived && data?['work_expected_completion_at'] != null) ...[
            const SizedBox(height: 10),
            Text('Dự kiến hoàn thành: ${format(data?['work_expected_completion_at'])}',
                style: Theme.of(context).textTheme.bodySmall),
            Text('Đã tính dịch vụ phát sinh được duyệt và thời gian chờ báo giá.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (data?['work_waiting_for_quotation'] == true) ...[
            const SizedBox(height: 8),
            const Text('Đang chờ khách phản hồi báo giá; thời gian chờ không tính là thợ làm chậm.'),
          ],
          if (data?['work_late'] == true) ...[
            const SizedBox(height: 8),
            Text('Thời gian làm việc vượt dự kiến hơn 15 phút.',
                style: TextStyle(color: colorScheme.error)),
          ],
          if (phase == 'TRAVELLING') ...[
            const SizedBox(height: 8),
            Text('ETA là ước tính lúc khởi hành, không theo dõi GPS liên tục.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh, size: 18), label: const Text('Làm mới'))),
        ]),
      ),
    );
  }
}
