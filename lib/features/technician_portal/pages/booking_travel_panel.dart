import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/technician_portal_repository.dart';

/// Samples GPS only when confirming departure and arrival.
/// Travel time is estimated at departure; no continuous tracking.
class BookingTravelPanel extends StatefulWidget {
  const BookingTravelPanel({super.key, required this.bookingId, required this.repository, this.onArrived});
  final String bookingId;
  final TechnicianPortalRepository repository;
  final VoidCallback? onArrived;

  @override
  State<BookingTravelPanel> createState() => _BookingTravelPanelState();
}

class _BookingTravelPanelState extends State<BookingTravelPanel> {
  Map<String, dynamic>? status;
  String? error;
  bool busy = false;
  Timer? clock;
  DateTime? lastReminderAt;
  bool reminderOpen = false;
  bool departureReminderDismissed = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    // A local foreground countdown. This does not pretend to deliver push
    // notifications while the app is closed or backgrounded.
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _maybeRemindDeparture();
    });
  }

  @override
  void dispose() { clock?.cancel(); super.dispose(); }

  String _countdown(DateTime target) {
    final difference = target.difference(DateTime.now());
    if (difference.isNegative) {
      final past = difference.abs();
      return 'Đã quá giờ hẹn ${past.inMinutes} phút';
    }
    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
    return 'Còn $hours:$minutes:$seconds đến giờ hẹn';
  }

  void _maybeRemindDeparture() {
    if (!mounted || reminderOpen || status?['status'] != 'NOT_STARTED') return;
    final scheduled = DateTime.tryParse('${status?['scheduled_at'] ?? ''}')?.toLocal();
    if (scheduled == null) return;
    // Fixed 30-minute foreground reminder until pre-departure ETA is available.
    final now = DateTime.now();
    final seconds = (status?['predeparture_duration_seconds'] as num?)?.toInt();
    if (now.isBefore(scheduled.subtract(Duration(seconds: seconds ?? 1800) + const Duration(minutes: 10)))) return;
    if (lastReminderAt != null && now.difference(lastReminderAt!) < const Duration(minutes: 5)) return;
    lastReminderAt = now;
    reminderOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) { reminderOpen = false; return; }
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nhắc bắt đầu di chuyển'),
          content: Text('Bạn có lịch hẹn lúc ${_date(scheduled.toIso8601String())}. '
              'Hãy bắt đầu di chuyển để đến đúng giờ.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Nhắc lại sau 5 phút')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xác nhận di chuyển')),
          ],
        ),
      );
      reminderOpen = false;
      if (leave == true && mounted && status?['status'] == 'NOT_STARTED') {
        await _confirmStart();
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final data = await widget.repository.travelStatus(widget.bookingId);
      if (mounted) { setState(() { status = data; error = null; }); _maybeRemindDeparture(); }
    } catch (e) { if (mounted) setState(() { error = 'Không tải được thông tin hành trình: $e'; }); }
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Vui lòng bật dịch vụ định vị GPS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw StateError('Vui lòng cấp quyền truy cập vị trí cho ứng dụng.');
    }
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
  }

  void _showTravelMessage(String message, {bool failure = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 6),
      backgroundColor: failure ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _confirmStart() async {
    final scheduled = DateTime.tryParse('${status?['scheduled_at'] ?? ''}')?.toLocal();
    final seconds = (status?['predeparture_duration_seconds'] as num?)?.toInt();
    final recommended = scheduled?.subtract(
      Duration(seconds: seconds ?? 1800) + const Duration(minutes: 10));
    if (recommended != null && DateTime.now().isBefore(recommended)) {
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Di chuyển sớm hơn dự kiến'),
        content: Text('Giờ hẹn: ${_date(scheduled!.toIso8601String())}. '
          'Bạn có chắc muốn bắt đầu di chuyển ngay không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quay lại')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn di chuyển')),
        ],
      ));
      if (confirmed != true || !mounted) return;
    }
    await _send('start');
  }

  Future<void> _send(String action, {bool silent = false}) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      // Only departure needs GPS to calculate ETA. Arrival is confirmed manually.
      final position = action == 'arrive' ? null : await _position();
      final data = await widget.repository.updateTravel(
        widget.bookingId, action, position?.latitude, position?.longitude);
      if (!mounted) return;
      final nextPhase = data['status']?.toString();
      if (nextPhase == null) {
        throw StateError('Máy chủ không trả về trạng thái hành trình.');
      }
      setState(() { status = {...?status, ...data}; error = null; });
      // Trust the successful arrival response before refreshing; otherwise a
      // failed refresh could conceal the successful arrival and block navigation.
      if (action == 'arrive' && nextPhase == 'ARRIVED') {
        _showTravelMessage('Đã xác nhận đến nơi thành công.');
        widget.onArrived?.call();
        return;
      }
      if (action == 'arrive') {
        throw StateError('Máy chủ chưa xác nhận đến nơi (trạng thái: $nextPhase).');
      }
      _showTravelMessage(data['routing_available'] == false
          ? 'Đã bắt đầu di chuyển. Chưa có giờ đến dự kiến; hãy xác nhận khi đến nơi.'
          : 'Đã xác nhận bắt đầu di chuyển.');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst(RegExp(r'^(Bad state|Exception):\s*'), '');
      setState(() { error = message; });
      if (!silent) _showTravelMessage(message, failure: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _date(dynamic value) {
    final dt = DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (dt == null) return 'Chưa có';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final phase = status?['status']?.toString() ?? 'NOT_STARTED';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('DI CHUYỂN ĐẾN KHÁCH', style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: 0.7,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(phase == 'ARRIVED' ? 'Đã đến nơi lúc ${_date(status?['arrived_at'])}'
            : phase == 'TRAVELLING' ? 'Đang di chuyển · Dự kiến đến: ${_date(status?['eta_at'])}'
            : 'Chưa bắt đầu di chuyển'),
        if (phase == 'NOT_STARTED' && status?['predeparture_duration_seconds'] != null)
        Text('Thời gian di chuyển dự kiến: ${((status!['predeparture_duration_seconds'] as num) / 60).ceil()} phút',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      if (phase == 'NOT_STARTED' &&
            DateTime.tryParse('${status?['scheduled_at'] ?? ''}') != null)
          Text(_countdown(DateTime.parse('${status!['scheduled_at']}').toLocal()),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        if (status?['arrival_late'] == true && phase != 'ARRIVED')
          const Text('Đã quá giờ hẹn 15 phút, hãy cập nhật trạng thái đến nơi.',
              style: TextStyle(color: Colors.deepOrange)),
        if (phase == 'ARRIVED' && status?['arrival_late'] == true)
          Text('Bạn đã đến trễ ${status?['arrival_late_minutes'] ?? 15} phút. Khách đã được thông báo; hãy trao đổi qua tin nhắn nếu cần.',
              style: const TextStyle(color: Colors.deepOrange)),
        if (phase == 'ARRIVED' && status?['scheduled_at'] != null &&
            DateTime.tryParse('${status!['scheduled_at']}')?.toLocal().subtract(const Duration(minutes: 15)).isAfter(DateTime.now()) == true)
          Text(status?['early_start_approved'] == true
            ? 'Khách đã xác nhận đồng ý bắt đầu sửa sớm. Tiếp tục quy trình công việc bình thường.'
            : 'Bạn đến sớm hơn 15 phút. Cần khách đồng ý để bắt đầu ngay; nếu chưa đồng ý, hãy chờ đến khi còn 15 phút trước giờ hẹn. Giờ hẹn: ${_date(status!['scheduled_at'])}.',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        if (phase == 'ARRIVED' && status?['early_start_approved'] != true &&
            status?['early_start_allowed'] != true &&
            DateTime.tryParse('${status?['scheduled_at'] ?? ''}')?.toLocal().subtract(const Duration(minutes: 15)).isAfter(DateTime.now()) == true) TextButton.icon(
          onPressed: busy ? null : _refresh,
          icon: const Icon(Icons.refresh), label: const Text('Kiểm tra xác nhận của khách')),
        if (phase == 'ARRIVED' && (status?['early_start_allowed'] == true ||
            (DateTime.tryParse('${status?['scheduled_at'] ?? ''}')?.toLocal().subtract(const Duration(minutes: 15)).isAfter(DateTime.now()) == false)))
          const Text('Đã đến nơi. Có thể thực hiện công việc theo lịch hẹn.'),
        if (phase == 'ARRIVED' && status?['work_expected_completion_at'] != null)
          Text('Dự kiến hoàn thành: ${_date(status?['work_expected_completion_at'])}'),
        if (status?['work_waiting_for_quotation'] == true)
          const Text('Đang chờ khách duyệt báo giá; thời gian chờ được loại khỏi thời gian làm.'),
        if (status?['work_late'] == true)
          const Text('Đã quá thời gian làm việc dự kiến hơn 15 phút.',
              style: TextStyle(color: Colors.deepOrange)),
        if (phase == 'TRAVELLING' && status?['eta_at'] != null &&
            status?['scheduled_at'] != null &&
            (DateTime.tryParse('${status!['eta_at']}')?.isAfter(
              (DateTime.tryParse('${status!['scheduled_at']}') ?? DateTime.now()).add(const Duration(minutes: 15))) ?? false))
          const Text('Dự kiến đến trễ từ 15 phút. Khách đã được thông báo; bạn có thể nhắn tin trao đổi.',
              style: TextStyle(color: Colors.deepOrange)),
        if (phase == 'TRAVELLING') Text(
            status?['eta_at'] == null
                ? 'Chưa tính được thời gian di chuyển. Khi đến nơi, hãy bấm xác nhận.'
                : DateTime.now().isAfter(DateTime.tryParse('${status!['eta_at']}')?.toLocal() ?? DateTime.now())
                ? 'Đã qua giờ đến dự kiến nhưng chưa xác nhận Đã đến nơi.'
                : 'Thời gian đi dự kiến: ${(((status?['duration_seconds'] as num?)?.toDouble() ?? 0) / 60).ceil()} phút. Không theo dõi GPS liên tục.'),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        if (phase == 'NOT_STARTED') FilledButton.icon(
            onPressed: busy ? null : _confirmStart,
            icon: const Icon(Icons.directions_bike), label: const Text('Bắt đầu di chuyển')),
        if (phase == 'TRAVELLING') ...[
          FilledButton(onPressed: busy ? null : () => _send('arrive'),
              child: const Text('Xác nhận đã đến nơi')),
        ],
        if (busy) const LinearProgressIndicator(),
      ]),
    ));
  }
}
