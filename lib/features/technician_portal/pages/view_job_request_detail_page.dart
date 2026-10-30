import '../../chat/booking_chat_page.dart';
import '../../payments/pages/payment_page.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../quotations/pages/quotation_page.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/service_text.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/view_job_request.dart';
import '../repositories/technician_portal_repository.dart';
import 'customer_ac_service_history_page.dart';

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
  final Map<String, ({String brandName, String modelName})> _unitEdits = {};

  bool get _canViewAcHistory =>
      widget.repository != null &&
      widget.request.booking.units.any((unit) => unit.id.isNotEmpty);

  Widget _buildAcHistoryButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _submitting ? null : _showAcHistoryPicker,
      icon: const Icon(Icons.history_rounded, size: 19),
      label: Text(Localizations.localeOf(context).languageCode == 'vi'
          ? 'Xem lịch sử dịch vụ máy lạnh' : 'View Customer AC Service History'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF087F91),
        backgroundColor: const Color(0xFFEAF7F8),
        side: const BorderSide(color: Color(0xFFB7E3E7)),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
  );

  Future<void> _showAcHistoryPicker() async {
    final units = widget.request.booking.units
        .where((unit) => unit.id.isNotEmpty)
        .toList();
    if (units.isEmpty || widget.repository == null) return;

    final unit = units.length == 1
        ? units.first
        : await showModalBottomSheet<ViewJobRequestUnit>(
            context: context,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? 'Chọn máy lạnh' : 'Select an AC unit',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final unit in units)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEAF7F8),
                        foregroundColor: Color(0xFF087F91),
                        child: Icon(Icons.ac_unit_rounded),
                      ),
                      title: Text(
                        '${Localizations.localeOf(context).languageCode == 'vi' ? 'Máy lạnh' : 'Unit'} ${unit.unitNumber > 0 ? unit.unitNumber : ''}'
                            .trim(),
                      ),
                      subtitle: Text(
                        [unit.brandName, unit.modelName]
                            .where((value) => value?.trim().isNotEmpty == true)
                            .join(' '),
                      ),
                      onTap: () => Navigator.of(context).pop(unit),
                    ),
                ],
              ),
            ),
          );
    if (unit == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerAcServiceHistoryPage(
          requestId: widget.request.id,
          unitId: unit.id,
          customerName: widget.request.customer.name,
          address: widget.request.booking.address,
          repository: widget.repository!,
        ),
      ),
    );
  }

  Future<void> _editAcUnit(ViewJobRequestUnit unit) async {
    final repository = widget.repository;
    if (repository == null || widget.request.status != 'ACCEPTED') return;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String tr(String v, String e) => vi ? v : e;
    List<Map<String, dynamic>> brands;
    try {
      brands = await repository.acBrands();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Không tải được danh sách hãng.', 'Unable to load AC brands.')),
        ));
      }
      return;
    }
    if (!mounted) return;
    String? selectedBrand = brands.any((b) => b['id']?.toString() == unit.brandId)
        ? unit.brandId : null;
    String? selectedModel = unit.modelId;
    List<Map<String, dynamic>> models = [];
    bool loadingModels = false;
    String? loadError;
    bool initialized = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> loadModels(String brandId) async {
            setSheetState(() { loadingModels = true; loadError = null; });
            try {
              final next = await repository.acModels(brandId);
              if (!sheetContext.mounted) return;
              if (selectedBrand != brandId) return;
              setSheetState(() {
                models = next;
                loadingModels = false;
                if (!models.any((m) => m['id']?.toString() == selectedModel)) {
                  selectedModel = null;
                }
              });
            } catch (_) {
              if (sheetContext.mounted) {
                setSheetState(() {
                  loadingModels = false;
                  loadError = tr('Không tải được danh sách model.', 'Unable to load models.');
                });
              }
            }
          }
          if (!initialized) {
            initialized = true;
            if (selectedBrand != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetContext.mounted) loadModels(selectedBrand!);
              });
            }
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Xác nhận thông tin máy lạnh', 'Confirm AC information'),
                  style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(tr('Hãng máy lạnh', 'AC Brand')),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedBrand,
                  hint: Text(tr('Chọn hãng', 'Select brand')),
                  items: brands.map((brand) => DropdownMenuItem<String>(
                    value: brand['id']?.toString(),
                    child: Text(brand['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    setSheetState(() { selectedBrand = value; selectedModel = null; models = []; });
                    if (value != null) loadModels(value);
                  },
                ),
                const SizedBox(height: 14),
                Text(tr('Model máy lạnh', 'AC Model')),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: models.any((m) => m['id']?.toString() == selectedModel)
                      ? selectedModel : null,
                  hint: Text(loadingModels
                      ? tr('Đang tải...', 'Loading...') : tr('Chọn model', 'Select model')),
                  items: models.map((model) => DropdownMenuItem<String>(
                    value: model['id']?.toString(),
                    child: Text(model['model_name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: selectedBrand == null || loadingModels
                      ? null : (value) => setSheetState(() => selectedModel = value),
                ),
                if (loadError != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(loadError!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: selectedBrand == null || selectedModel == null || loadingModels
                      ? null : () async {
                          final brandId = selectedBrand!;
                          final modelId = selectedModel!;
                          setSheetState(() => loadingModels = true);
                          try {
                            await repository.updateJobAcInformation(
                              widget.request.id, unit.id, brandId: brandId, modelId: modelId);
                            if (!mounted || !sheetContext.mounted) return;
                            final name = brands.firstWhere((b) => b['id']?.toString() == brandId)['name']?.toString() ?? '';
                            final modelName = models.firstWhere((m) => m['id']?.toString() == modelId)['model_name']?.toString() ?? '';
                            setState(() => _unitEdits[unit.id] = (brandName: name, modelName: modelName));
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(tr('Đã lưu thông tin máy lạnh.', 'AC information saved.'))));
                          } catch (_) {
                            if (!sheetContext.mounted) return;
                            setSheetState(() { loadingModels = false;
                              loadError = tr('Không lưu được. Vui lòng thử lại.', 'Unable to save. Please retry.'); });
                          }
                        },
                  child: Text(tr('Lưu thông tin', 'Save information')),
                ),
              ],
            )),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.request.status == 'COMPLETED') {
      _loadPaymentStatus();
    }
  }

  Future<void> _loadPaymentStatus() async {
    try {
      final summary = await _paymentRepository.technicianSummary(
        widget.request.booking.id,
      );
      final rows = (summary['payments'] as List? ?? []).whereType<Map>();
      if (!mounted) return;
      setState(() {
        _isPaid = rows.any((p) => p['payment_status'] == 'SUCCESS');
        _paymentPending = rows.any(
          (p) =>
              p['payment_status'] == 'PENDING' ||
              p['payment_status'] == 'PROCESSING',
        );
      });
    } catch (_) {
      if (mounted) setState(() => _isPaid = null);
    }
  }

  Future<void> _openPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PaymentPage(bookingId: widget.request.booking.id, technician: true),
      ),
    );
    if (mounted) await _loadPaymentStatus();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final booking = request.booking;
    final notes = _notes(booking);
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String bilingual(String viText, String enText) => vi ? viText : enText;
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
        actions: [
          if (widget.request.status == 'ACCEPTED' || widget.request.status == 'COMPLETED')
            IconButton(
              tooltip: 'Chat',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BookingChatPage(bookingId: widget.request.booking.id),
              )),
            ),
        ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _UnitSpecification(
                            unit: booking.units[index],
                            showDivider: false,
                            displayBrandModel: _unitEdits[booking.units[index].id],
                          ),
                          if (request.status == 'ACCEPTED' && widget.repository != null &&
                              booking.units[index].id.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _editAcUnit(booking.units[index]),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(bilingual('Xác nhận hãng / model', 'Confirm brand / model')),
                              ),
                            ),
                          if (index < booking.units.length - 1) const Divider(height: 24),
                        ],
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuotationPage(
                        bookingId: request.booking.id,
                        technician: true,
                        createType: 'ADDITIONAL',
                        currentAmount: request.booking.totalAmount,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    bilingual(
                      'Tạo báo giá bổ sung',
                      'Create Additional Quotation',
                    ),
                  ),
                ),
              ],
              if (request.status == 'COMPLETED') ...[
                const SizedBox(height: 12),
                _Section(
                  label: bilingual('TRẠNG THÁI THANH TOÁN', 'PAYMENT STATUS'),
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPaid == true
                              ? Icons.verified_rounded
                              : _paymentPending
                              ? Icons.schedule_rounded
                              : Icons.receipt_long_outlined,
                          color: _isPaid == true
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isPaid == true
                                ? bilingual('Đã thanh toán', 'Paid')
                                : _isPaid == null
                                ? bilingual(
                                    'Chưa xác định thanh toán',
                                    'Payment status unavailable',
                                  )
                                : _paymentPending
                                ? bilingual(
                                    'Đang chờ thanh toán',
                                    'Pending payment',
                                  )
                                : bilingual('Chưa thanh toán', 'Unpaid'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openPayment,
                        icon: Icon(
                          _isPaid == true
                              ? Icons.receipt_long_outlined
                              : Icons.qr_code_2,
                        ),
                        label: Text(
                          _isPaid == true
                              ? bilingual(
                                  'Xem chi tiết thanh toán',
                                  'View payment details',
                                )
                              : _paymentPending
                              ? bilingual(
                                  'Kiểm tra thanh toán / Hiện QR',
                                  'Check payment / Show QR',
                                )
                              : bilingual(
                                  'Tiền mặt / Tạo QR',
                                  'Cash / Generate QR',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canViewAcHistory) ...[
                      _buildAcHistoryButton(),
                      const SizedBox(height: 12),
                    ],
                    Row(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canViewAcHistory) ...[
                      _buildAcHistoryButton(),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (request.canCancelAcceptedJob)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : _confirmCancelAccepted,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
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
                                  : const Icon(
                                      Icons.check_circle_outline_rounded,
                                    ),
                              label: Text(context.tr('jobComplete')),
                            ),
                          ),
                      ],
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
    return '${localizedServiceName(context, booking.primaryServiceName)}$suffix';
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
  const _UnitSpecification({required this.unit, required this.showDivider, this.displayBrandModel});

  final ViewJobRequestUnit unit;
  final bool showDivider;
  final ({String brandName, String modelName})? displayBrandModel;

  @override
  Widget build(BuildContext context) {
    final brandAndModel = [
      displayBrandModel?.brandName ?? unit.brandName,
      displayBrandModel?.modelName ?? unit.modelName,
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
              .map((service) => localizedServiceName(context, service.name))
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
