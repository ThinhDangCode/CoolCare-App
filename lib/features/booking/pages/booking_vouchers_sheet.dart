import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../repositories/booking_detail_repository.dart';

class BookingVouchersSheet extends StatefulWidget {
  const BookingVouchersSheet({super.key, required this.bookingId, required this.repository});
  final String bookingId;
  final BookingDetailRepository repository;

  @override
  State<BookingVouchersSheet> createState() => _BookingVouchersSheetState();
}

class _BookingVouchersSheetState extends State<BookingVouchersSheet> {
  late Future<List<Map<String, dynamic>>> _items;
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;
  static final _codePattern = RegExp(r'^[A-Z0-9_-]{3,20}$');

  @override
  void initState() {
    super.initState();
    _items = widget.repository.availableVouchers(widget.bookingId);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _money(dynamic amount) {
    final n = num.tryParse('$amount') ?? 0;
    return '${n.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      const known = {
        'VOUCHER_NOT_FOUND': 'voucherErrorNotFound',
        'VOUCHER_REQUIRES_ACCEPTED_QUOTATION': 'voucherErrorRequiresQuotation',
        'VOUCHER_NOT_ELIGIBLE': 'voucherErrorNotEligible',
        'VOUCHER_CANNOT_BE_APPLIED': 'voucherErrorNotEligible',
        'VOUCHER_NOT_ASSIGNED': 'voucherErrorNotAssigned',
        'BOOKING_NOT_ELIGIBLE': 'voucherErrorBookingStatus',
        'BOOKING_NOT_FOUND': 'voucherErrorBookingNotFound',
        'INVALID_ID': 'voucherErrorBookingNotFound',
        'VALIDATION_ERROR': 'voucherInvalidCode',
      };
      final key = known[error.code];
      if (key != null) {
        return context.tr(key);
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        return context.tr('voucherErrorUnauthorized');
      }
      if (error.statusCode == 409 || error.statusCode == 422) {
        return context.tr('voucherErrorNotEligible');
      }
    }
    return context.tr('voucherApplyFailed');
  }

  Future<void> _apply(String input) async {
    if (_submitting) return;
    final code = input.trim().toUpperCase();
    if (!_codePattern.hasMatch(code)) {
      setState(() => _error = context.tr('voucherInvalidCode'));
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.repository.applyVoucher(widget.bookingId, code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('voucherTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: _code,
            maxLength: 20,
            textCapitalization: TextCapitalization.characters,
            enabled: !_submitting,
            onChanged: (_) { if (_error != null) setState(() => _error = null); },
            decoration: InputDecoration(
              labelText: context.tr('voucherCode'),
              counterText: '',
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 3,
            ),
          )),
          const SizedBox(width: 8),
          FilledButton(onPressed: _submitting ? null : () => _apply(_code.text), child: Text(context.tr('voucherApply'))),
        ]),
        const SizedBox(height: 8),
        Flexible(child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error!;

              debugPrint('Voucher load error: $error');

              if (error is ApiException) {
                debugPrint('Voucher HTTP status: ${error.statusCode}');
                debugPrint('Voucher error code: ${error.code}');
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _items = widget.repository.availableVouchers(
                            widget.bookingId,
                          );
                        });
                      },
                      child: Text(context.tr('bookingUi60')),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Padding(padding: const EdgeInsets.all(20), child: Text(context.tr('voucherEmpty')));
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final v = items[index];
                final eligible = v['eligible'] == true;
                final discount = v['discountType'] == 'PERCENTAGE' ? '${v['discountValue']}%' : _money(v['discountValue']);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${v['code']} · $discount', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    "${v['name']}\n"
                    "${context.tr('voucherMinOrder')}: ${_money(v['minimumOrderAmount'])}"
                    "${eligible ? '' : '\n${context.tr('voucherNotEligible')}'}",
                  ),
                  isThreeLine: true,
                  trailing: OutlinedButton(
                    onPressed: eligible && !_submitting ? () => _apply('${v['code']}') : null,
                    child: Text(context.tr('voucherApply'))),
                );
              },
            );
          },
        )),
      ]),
    ),
  );
}
