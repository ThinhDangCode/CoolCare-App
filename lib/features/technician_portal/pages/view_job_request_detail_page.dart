import '../../payments/pages/payment_page.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../quotations/pages/quotation_page.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
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

  @override
  State<ViewJobRequestDetailPage> createState() =>
      _ViewJobRequestDetailPageState();
}

class _ViewJobRequestDetailPageState extends State<ViewJobRequestDetailPage> {
  bool _submitting = false;
  final PaymentRepository _paymentRepository = PaymentRepository();
  bool? _isPaid;
  bool _paymentPending = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    try {
      final summary = await _paymentRepository.technicianSummary(widget.request.booking.id);
      final rows = (summary['payments'] as List? ?? []).whereType<Map>();
      if (!mounted) return;
      setState(() {
        _isPaid = rows.any((p) => p['payment_status'] == 'SUCCESS');
        _paymentPending = rows.any((p) =>
            p['payment_status'] == 'PENDING' || p['payment_status'] == 'PROCESSING');
      });
    } catch (_) {
      if (mounted) setState(() => _isPaid = null);
    }
  }

  Future<void> _openPayment() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
        PaymentPage(bookingId: widget.request.booking.id, technician: true)));
    if (mounted) await _loadPaymentStatus();
  }


  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final booking = request.booking;
    final notes = _notes(booking);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 54,
        centerTitle: false,
        leadingWidth: 48,
        leading: IconButton(
          tooltip: context.tr('back'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        titleSpacing: 0,
        title: Text(
          context.tr('jobDetails'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
                label: context.tr('jobServiceType'),
                children: [
                  Text(
                    _serviceTitle(booking),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${context.tr('jobCustomer')}: ${_value(context, request.customer.name)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Section(
                label: context.tr('jobScheduleLocation'),
                children: [
                  Text(
                    _date(context, booking.scheduledAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _value(context, booking.address),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (booking.units.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Section(
                  label: context.tr('jobAcSpecification'),
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
                  label: context.tr('jobCustomerNotes'),
                  children: [
                    Text(
                      notes,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
              if (request.status == 'ACCEPTED') ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                    QuotationPage(bookingId: request.booking.id, technician: true))),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Create / View Quotation'),
                ),
              ],
              const SizedBox(height: 12),
              _Section(label: 'PAYMENT STATUS', children: [
                Row(children: [
                  Icon(_isPaid == true ? Icons.verified_rounded :
                       _paymentPending ? Icons.schedule_rounded : Icons.receipt_long_outlined,
                       color: _isPaid == true ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_isPaid == true ? 'Paid' :
                      _isPaid == null ? 'Payment status unavailable' :
                      _paymentPending ? 'Pending payment' : 'Unpaid',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: _openPayment,
                  icon: Icon(_isPaid == true ? Icons.receipt_long_outlined : Icons.qr_code_2),
                  label: Text(_isPaid == true ? 'View payment details' :
                      _paymentPending ? 'Check payment / Show QR' : 'Cash / Generate QR'),
                )),
              ]),
              const SizedBox(height: 14),
              _Section(
                label: context.tr('jobBookingInformation'),
                children: [
                  _InformationRow(
                    label: context.tr('jobBookingCode'),
                    value: booking.code,
                  ),
                  const SizedBox(height: 8),
                  _InformationRow(
                    label: context.tr('jobContact'),
                    value: [
                      booking.recipientName,
                      booking.recipientPhone,
                    ].where((value) => value.trim().isNotEmpty).join(' · '),
                  ),
                  if (request.matchReason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InformationRow(
                      label: context.tr('jobMatchReason'),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
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
                        child: Text(context.tr('jobDecline')),
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
                            : Text(context.tr('jobAccept')),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
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
                          label: Text(context.tr('cancel')),
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
                          label: Text(context.tr('jobComplete')),
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
        : ' (${context.tr(count == 1 ? 'jobUnitCount' : 'jobUnitsCount').replaceFirst('{count}', '$count')})';
    return '${booking.primaryServiceName}$suffix';
  }

  Future<void> _confirmAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('jobAcceptTitle')),
        content: Text(context.tr('jobAcceptMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('jobAccept')),
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
        title: Text(context.tr('jobDeclineTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('jobDeclineMessage')),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => enteredReason = value,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('jobReasonOptional'),
                hintText: context.tr('jobDeclineReasonHint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(context).pop(enteredReason.trim()),
            child: Text(context.tr('jobDecline')),
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
        title: Text(context.tr('jobCompleteTitle')),
        content: Text(context.tr('jobCompleteMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('jobComplete')),
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
          title: Text(context.tr('jobCancelAcceptedTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('jobCancelAcceptedMessage')),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                onChanged: (value) {
                  reason = value.trim();
                  setDialogState(() {});
                },
                decoration: InputDecoration(
                  labelText: context.tr('jobCancellationReason'),
                  hintText: context.tr('jobReasonMinLength'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('back')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: reason.length < 5
                  ? null
                  : () => Navigator.of(dialogContext).pop(reason),
              child: Text(context.tr('jobCancel')),
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
                ? context.tr('jobCancelledSuccess')
                : context
                      .tr('jobPenaltyApplied')
                      .replaceFirst('{count}', '$penalty'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('jobCancelFailed'))));
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
        SnackBar(content: Text(context.tr('jobCompletionSubmitted'))),
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
          SnackBar(content: Text(context.tr('jobCompleteFailed'))),
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
                ? context.tr('jobAcceptedSuccess')
                : context.tr('jobDeclinedSuccess'),
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
          SnackBar(content: Text(context.tr('jobResponseFailed'))),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
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
          _InformationRow(
            label: context.tr('jobUnit'),
            value: unit.unitNumber.toString(),
          ),
          const SizedBox(height: 8),
        ],
        _InformationRow(
          label: context.tr('jobBrandModel'),
          value: brandAndModel,
        ),
        const SizedBox(height: 8),
        _InformationRow(
          label: context.tr('jobServices'),
          value: unit.services
              .map((service) => service.name)
              .where((name) => name.trim().isNotEmpty)
              .join(', '),
        ),
        if (showDivider) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          _value(context, value),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

String _value(BuildContext context, String value) =>
    value.trim().isEmpty ? context.tr('jobNotProvided') : value;

String _date(BuildContext context, DateTime? value) {
  if (value == null) return context.tr('jobNotScheduled');
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} - ${two(local.hour)}:${two(local.minute)}';
}
