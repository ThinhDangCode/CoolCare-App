import 'dart:async';
import 'package:flutter/material.dart';
import '../models/view_job_request.dart';

/// UI countdown only. The server remains authoritative for accepting jobs.
DateTime? jobRequestDeadline(ViewJobRequest request) {
  if (request.status != 'SELECTED') return null;
  final start = request.requestedAt;
  final tenMinutes = start?.add(const Duration(minutes: 10));
  final dates = <DateTime>[
    if (request.expiresAt != null) request.expiresAt!,
    if (tenMinutes != null) tenMinutes,
    if (request.booking.scheduledAt != null) request.booking.scheduledAt!,
  ];
  if (dates.isEmpty) return null;
  dates.sort();
  return dates.first;
}

class JobRequestDeadline extends StatefulWidget {
  const JobRequestDeadline({required this.request, super.key});
  final ViewJobRequest request;

  @override
  State<JobRequestDeadline> createState() => _JobRequestDeadlineState();
}

class _JobRequestDeadlineState extends State<JobRequestDeadline> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = jobRequestDeadline(widget.request);
    if (deadline == null) return const SizedBox.shrink();
    final remaining = deadline.difference(DateTime.now());
    final expired = remaining <= Duration.zero;
    final warning = !expired && remaining <= const Duration(minutes: 2);
    final seconds = expired ? 0 : remaining.inSeconds + (remaining.inMilliseconds % 1000 == 0 ? 0 : 1);
    final minutesText = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsText = (seconds % 60).toString().padLeft(2, '0');
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final label = expired
        ? (vi ? 'Yêu cầu đã hết hạn. Không thể nhận việc.' : 'Request expired. You cannot accept this job.')
        : warning
            ? (vi ? 'Sắp hết hạn! Còn $minutesText:$secondsText để nhận việc.' : 'Expiring soon! $minutesText:$secondsText left to accept.')
            : (vi ? 'Thời gian nhận việc còn $minutesText:$secondsText' : 'Time left to accept: $minutesText:$secondsText');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: expired ? const Color(0xFFFEE2E2) : warning ? const Color(0xFFFFF3CD) : const Color(0xFFEAF7F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(expired ? Icons.event_busy : warning ? Icons.warning_amber_rounded : Icons.timer_outlined,
            color: expired ? const Color(0xFFB91C1C) : warning ? const Color(0xFF92400E) : const Color(0xFF087F91)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }
}
