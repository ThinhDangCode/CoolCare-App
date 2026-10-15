import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/view_job_request.dart';
import '../repositories/technician_portal_repository.dart';

class ViewJobRequestDetailPage extends StatefulWidget {
  const ViewJobRequestDetailPage({
    required this.request,
    this.repository,
    super.key,
  });

  final ViewJobRequest request;
  final TechnicianPortalRepository? repository;

  static const _text = Color(0xFF193943);
  static const _muted = Color(0xFF657F8A);
  static const _border = Color(0xFFDBE7EB);

  @override
  State<ViewJobRequestDetailPage> createState() =>
      _ViewJobRequestDetailPageState();
}

class _ViewJobRequestDetailPageState extends State<ViewJobRequestDetailPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final booking = request.booking;
    final notes = _notes(booking);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        toolbarHeight: 54,
        centerTitle: false,
        leadingWidth: 48,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        titleSpacing: 0,
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: ViewJobRequestDetailPage._text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: ViewJobRequestDetailPage._border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                label: 'SERVICE TYPE',
                children: [
                  Text(
                    _serviceTitle(booking),
                    style: const TextStyle(
                      color: ViewJobRequestDetailPage._text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Customer: ${_value(request.customer.name)}',
                    style: const TextStyle(
                      color: ViewJobRequestDetailPage._muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Section(
                label: 'SCHEDULE & LOCATION',
                children: [
                  Text(
                    _date(booking.scheduledAt),
                    style: const TextStyle(
                      color: ViewJobRequestDetailPage._text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _value(booking.address),
                    style: const TextStyle(
                      color: ViewJobRequestDetailPage._muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (booking.units.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Section(
                  label: 'AC SPECIFICATION',
                  children: [
                    for (var index = 0; index < booking.units.length; index++)
                      _UnitSpecification(
                        unit: booking.units[index],
                        showDivider: index < booking.units.length - 1,
                      ),
                  ],
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Section(
                  label: 'CUSTOMER NOTES',
                  children: [
                    Text(
                      notes,
                      style: const TextStyle(
                        color: ViewJobRequestDetailPage._text,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              _Section(
                label: 'BOOKING INFORMATION',
                children: [
                  _InformationRow(label: 'Booking code:', value: booking.code),
                  const SizedBox(height: 8),
                  _InformationRow(
                    label: 'Contact:',
                    value: [
                      booking.recipientName,
                      booking.recipientPhone,
                    ].where((value) => value.trim().isNotEmpty).join(' · '),
                  ),
                  if (request.matchReason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InformationRow(
                      label: 'Match reason:',
                      value: request.matchReason!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: request.canRespond
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: ViewJobRequestDetailPage._border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _confirmDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          minimumSize: const Size.fromHeight(41),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _confirmAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: CoolCareColors.primary,
                          minimumSize: const Size.fromHeight(41),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Accept Job'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : request.canComplete || request.canCancelAcceptedJob
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: ViewJobRequestDetailPage._border),
                  ),
                ),
                child: Row(
                  children: [
                    if (request.canCancelAcceptedJob)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting
                              ? null
                              : _confirmCancelAccepted,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                        ),
                      ),
                    if (request.canCancelAcceptedJob && request.canComplete)
                      const SizedBox(width: 12),
                    if (request.canComplete)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _confirmComplete,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Complete Job'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String _notes(ViewJobRequestBooking booking) {
    final values = <String>[
      if (booking.description?.trim().isNotEmpty == true)
        booking.description!.trim(),
      ...booking.units
          .map((unit) => unit.description?.trim() ?? '')
          .where((value) => value.isNotEmpty),
    ];
    return values.toSet().join('\n');
  }

  String _serviceTitle(ViewJobRequestBooking booking) {
    final count = booking.units.length;
    final suffix = count == 0
        ? ''
        : ' ($count ${count == 1 ? 'unit' : 'units'})';
    return '${booking.primaryServiceName}$suffix';
  }

  Future<void> _confirmAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept this job?'),
        content: const Text(
          'The booking will move to Ongoing and the customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept Job'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _respond(accept: true);
  }

  Future<void> _confirmDecline() async {
    var enteredReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline this job?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This request will be removed from New Requests and the customer will be notified.',
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => enteredReason = value,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter a reason for declining',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(context).pop(enteredReason.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (reason != null) await _respond(accept: false, reason: reason);
  }

  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete this job?'),
        content: const Text(
          'The customer will be asked to confirm completion. The job stays Ongoing until they confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete Job'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _complete();
  }

  Future<void> _confirmCancelAccepted() async {
    var reason = '';
    final submittedReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancel accepted job?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The customer booking will be cancelled. A late cancellation may add penalty points.',
              ),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                onChanged: (value) {
                  reason = value.trim();
                  setDialogState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Cancellation reason',
                  hintText: 'At least 5 characters',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Back'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: reason.length < 5
                  ? null
                  : () => Navigator.of(dialogContext).pop(reason),
              child: const Text('Cancel Job'),
            ),
          ],
        ),
      ),
    );
    if (submittedReason != null) await _cancelAccepted(submittedReason);
  }

  Future<void> _cancelAccepted(String reason) async {
    final repository = widget.repository;
    if (repository == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await repository.cancelAcceptedJob(
        widget.request.id,
        reason: reason,
      );
      if (!mounted) return;
      final penalty = result.penaltyPoints;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            penalty == null
                ? 'Job cancelled successfully.'
                : 'Job cancelled. $penalty penalty points were applied.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to cancel this job. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _complete() async {
    final repository = widget.repository;
    if (repository == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await repository.completeJob(widget.request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completion submitted. Awaiting customer confirmation.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to complete this job. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _respond({required bool accept, String? reason}) async {
    final repository = widget.repository;
    if (repository == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await repository.respondToJobRequest(
        widget.request.id,
        accept: accept,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Job accepted successfully.'
                : 'Job declined successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save your response. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ViewJobRequestDetailPage._border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ViewJobRequestDetailPage._muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class _UnitSpecification extends StatelessWidget {
  const _UnitSpecification({required this.unit, required this.showDivider});

  final ViewJobRequestUnit unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final brandAndModel = [
      unit.brandName,
      unit.modelName,
    ].where((value) => value?.trim().isNotEmpty == true).join(' ');
    return Column(
      children: [
        if (unit.unitNumber > 0) ...[
          _InformationRow(label: 'Unit:', value: unit.unitNumber.toString()),
          const SizedBox(height: 8),
        ],
        _InformationRow(label: 'Brand & Model:', value: brandAndModel),
        const SizedBox(height: 8),
        _InformationRow(
          label: 'Services:',
          value: unit.services
              .map((service) => service.name)
              .where((name) => name.trim().isNotEmpty)
              .join(', '),
        ),
        if (showDivider) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: ViewJobRequestDetailPage._border),
          ),
        ],
      ],
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ViewJobRequestDetailPage._muted,
          fontSize: 13,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          _value(value),
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: ViewJobRequestDetailPage._text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

String _value(String value) => value.trim().isEmpty ? 'Not provided' : value;

String _date(DateTime? value) {
  if (value == null) return 'Not scheduled';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} - ${two(local.hour)}:${two(local.minute)}';
}
