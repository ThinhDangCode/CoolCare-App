import 'package:flutter/material.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../repositories/quotation_repository.dart';

String _text(BuildContext context, String vi, String en) =>
    Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

String _money(BuildContext context, Object? value) {
  final amount = (value is num ? value : num.tryParse('$value') ?? 0).round();
  final separator = Localizations.localeOf(context).languageCode == 'vi' ? '.' : ',';
  final digits = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => separator,
  );
  return Localizations.localeOf(context).languageCode == 'vi'
      ? '$digits đ'
      : '$digits VND';
}

String _status(BuildContext context, String status) => switch (status) {
  'DRAFT' => _text(context, 'Bản nháp', 'Draft'),
  'PENDING' => _text(context, 'Chờ phản hồi', 'Awaiting response'),
  'ACCEPTED' => _text(context, 'Đã chấp nhận', 'Accepted'),
  'REJECTED' => _text(context, 'Đã từ chối', 'Rejected'),
  _ => status,
};

class QuotationPage extends StatefulWidget {
  const QuotationPage({
    super.key,
    required this.bookingId,
    required this.technician,
    this.createType,
    this.currentAmount,
  });
  final String bookingId;
  final bool technician;
  final String? createType;
  final num? currentAmount;
  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  final repository = QuotationRepository();
  late Future<List<Map<String, dynamic>>> quotes;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    quotes = repository.list(widget.bookingId);
  }

  void _refresh() {
    setState(_reload);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) {
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_text(context, 'Báo giá', 'Quotations'))),
    floatingActionButton: widget.technician
        ? FloatingActionButton.extended(
            onPressed: busy
                ? null
                : () async {
                    final data = await quotes;
                    if (!context.mounted) return;
                    final hasInitial = data.any(
                      (q) => q['quotation_type'] == 'INITIAL',
                    );
                    final hasApprovedInitial = data.any(
                      (q) =>
                          q['quotation_type'] == 'INITIAL' &&
                          q['status'] == 'ACCEPTED',
                    );
                    final type =
                        widget.createType ??
                        (hasInitial ? 'ADDITIONAL' : 'INITIAL');
                    final acceptedAmount = data
                        .where((q) => q['status'] == 'ACCEPTED')
                        .fold<num>(0, (sum, q) {
                          final value = q['subtotal'] ?? q['total_amount'];
                          return sum +
                              (value is num
                                  ? value
                                  : num.tryParse('$value') ?? 0);
                        });
                    if (type == 'ADDITIONAL' &&
                        hasInitial &&
                        !hasApprovedInitial) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _text(context, 'Báo giá ban đầu phải được duyệt trước khi tạo báo giá bổ sung.', 'The initial quotation must be accepted before creating an additional quotation.'),
                          ),
                        ),
                      );
                      return;
                    }
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _QuotationEditor(
                          bookingId: widget.bookingId,
                          type: type,
                          repository: repository,
                          baseAmount: acceptedAmount > 0
                              ? acceptedAmount
                              : (widget.currentAmount ?? 0),
                        ),
                      ),
                    );
                    if (created == true) _refresh();
                  },
            icon: const Icon(Icons.add),
            label: Text(_text(context, 'Tạo báo giá', 'Create quotation')),
          )
        : null,
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: quotes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_text(context, 'Không tải được báo giá', 'Could not load quotations')}: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: _refresh, child: Text(_text(context, 'Thử lại', 'Retry'))),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return Center(
            child: Text(_text(context, 'Chưa có báo giá. Đơn vẫn sử dụng giá mặc định.', 'No quotations yet. The booking still uses the listed price.')),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final q = data[index];
            final status = q['status']?.toString() ?? '';
            final items = q['items'] is List ? q['items'] as List : const [];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['quotation_type'] == 'INITIAL'
                          ? _text(context, 'Báo giá ban đầu', 'Initial quotation')
                          : '${_text(context, 'Báo giá bổ sung', 'Additional quotation')} #${q['quotation_number']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text('${_text(context, 'Trạng thái', 'Status')}: ${_status(context, status)}'),
                    if ((q['issue_description']?.toString() ?? '').isNotEmpty)
                      Text('${_text(context, 'Lý do', 'Reason')}: ${q['issue_description']}'),
                    const Divider(),
                    for (final raw in items)
                      Builder(
                        builder: (_) {
                          final item = raw as Map;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['description']} × ${item['quantity']}',
                                  ),
                                ),
                                Text(_money(context, item['total_price'])),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(),
                    Text(
                      '${_text(context, 'Tổng cộng', 'Total')}: ${_money(context, q['total_amount'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.technician && status == 'DRAFT')
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => _run(() => repository.send('${q['id']}')),
                        child: Text(_text(context, 'Gửi báo giá', 'Send quotation')),
                      ),
                    if (!widget.technician && status == 'PENDING')
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => _run(
                                    () => repository.respond(
                                      '${q['id']}',
                                      'REJECTED',
                                    ),
                                  ),
                            child: Text(_text(context, 'Từ chối', 'Decline')),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () => _run(
                                    () => repository.respond(
                                      '${q['id']}',
                                      'ACCEPTED',
                                    ),
                                  ),
                            child: Text(_text(context, 'Chấp nhận', 'Accept')),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _QuotationEditor extends StatefulWidget {
  const _QuotationEditor({
    required this.bookingId,
    required this.type,
    required this.repository,
    required this.baseAmount,
  });
  final String bookingId;
  final String type;
  final QuotationRepository repository;
  final num baseAmount;
  @override
  State<_QuotationEditor> createState() => _QuotationEditorState();
}

class _QuotationEditorState extends State<_QuotationEditor> {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  final note = TextEditingController();
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unitPrice = TextEditingController();
  final items = <Map<String, dynamic>>[];
  bool sending = false;
  num get total => items.fold<num>(
    0,
    (sum, item) => sum + (item['quantity'] as num) * (item['unitPrice'] as num),
  );

  @override
  void dispose() {
    reason.dispose();
    note.dispose();
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
    super.dispose();
  }

  void _add() {
    final q = num.tryParse(quantity.text);
    final p = num.tryParse(unitPrice.text);
    if (description.text.trim().isEmpty ||
        q == null ||
        q <= 0 ||
        p == null ||
        p < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(context, 'Nhập mô tả, số lượng và đơn giá hợp lệ.', 'Enter a description, quantity and valid unit price.')),
        ),
      );
      return;
    }
    setState(
      () => items.add({
        'itemType': 'LABOR',
        'description': description.text.trim(),
        'quantity': q,
        'unit': 'lần',
        'unitPrice': p,
        'discountAmount': 0,
      }),
    );
    description.clear();
    quantity.text = '1';
    unitPrice.clear();
  }

  Future<void> _save() async {
    if (items.isEmpty ||
        (widget.type == 'ADDITIONAL' && reason.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(context, 'Hãy thêm ít nhất một hạng mục và lý do nếu là báo giá bổ sung.', 'Add at least one item and provide a reason for additional work.')),
        ),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await widget.repository.create(
        widget.bookingId,
        type: widget.type,
        items: items,
        issueDescription: reason.text.trim(),
        note: note.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  String _money(num value) {
    return _moneyForLocale(value);
  }

  String _moneyForLocale(num value) {
    final amount = value.round().toString();
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final digits = amount.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => vi ? '.' : ',');
    return vi ? '$digits đ' : '$digits VND';
  }

  Widget _section({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.appAccentSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdditional = widget.type == 'ADDITIONAL';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdditional
              ? _text(context, 'Tạo báo giá bổ sung', 'Create additional quotation')
              : _text(context, 'Tạo báo giá', 'Create quotation'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  CoolCareColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdditional
                            ? _text(context, 'Báo giá công việc phát sinh', 'Additional work quotation')
                            : _text(context, 'Báo giá dịch vụ', 'Service quotation'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isAdditional
                            ? _text(context, 'Chỉ thêm công việc ngoài dịch vụ ban đầu. Số tiền được duyệt sẽ cộng vào tổng đơn.', 'Only add work outside the original service. Accepted charges will be added to the booking total.')
                            : _text(context, 'Liệt kê các hạng mục để khách xem và duyệt báo giá.', 'List the work and prices for the customer to review and approve.'),
                        style: const TextStyle(
                          color: Color(0xFFE4FAFB),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isAdditional) ...[
            _section(
              context: context,
              icon: Icons.info_outline_rounded,
              title: _text(context, 'Lý do phát sinh', 'Reason for additional work'),
              subtitle: _text(context, 'Giải thích vì sao công việc này không nằm trong dịch vụ ban đầu.', 'Explain why this work was not included in the original service.'),
              child: TextField(
                controller: reason,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _text(context, 'Ví dụ: Cần bổ sung gas sau khi kiểm tra', 'Example: Refrigerant needs topping up after inspection'),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _section(
            context: context,
            icon: Icons.home_repair_service_outlined,
            title: _text(context, 'Chi tiết công việc', 'Work details'),
            subtitle: _text(context, 'Thêm từng hạng mục cùng số lượng và đơn giá.', 'Add each task with its quantity and unit price.'),
            child: Column(
              children: [
                TextField(
                  controller: description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _text(context, 'Tên công việc hoặc dịch vụ', 'Task or service name'),
                    hintText: _text(context, 'Nhập công việc cần thực hiện', 'Describe the work'),
                    prefixIcon: const Icon(Icons.build_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _text(context, 'Số lượng', 'Quantity'),
                          prefixIcon: const Icon(Icons.numbers_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unitPrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _text(context, 'Đơn giá', 'Unit price'),
                          suffixText: 'VND',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(_text(context, 'Thêm vào báo giá', 'Add to quotation')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context: context,
            icon: Icons.format_list_bulleted_rounded,
            title: _text(context, 'Hạng mục báo giá', 'Quotation items'),
            subtitle: items.isEmpty
                ? _text(context, 'Chưa thêm hạng mục nào.', 'No items added yet.')
                : _text(context, 'Đã thêm ${items.length} hạng mục', '${items.length} ${items.length == 1 ? 'item' : 'items'} added'),
            child: items.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSoftSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.playlist_add_rounded,
                          color: context.appMuted,
                          size: 34,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _text(context, 'Thêm ít nhất một hạng mục để tiếp tục', 'Add at least one item to continue'),
                          style: TextStyle(
                            color: context.appMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.appSoftSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.appAccentSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${items[i]['description']}',
                                      style: TextStyle(
                                        color: context.appText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${items[i]['quantity']} × ${_money(items[i]['unitPrice'] as num)}',
                                      style: TextStyle(
                                        color: context.appMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _money(
                                      (items[i]['quantity'] as num) *
                                          (items[i]['unitPrice'] as num),
                                    ),
                                    style: TextStyle(
                                      color: context.appText,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      tooltip: _text(context, 'Xóa hạng mục', 'Remove item'),
                                      onPressed: () =>
                                          setState(() => items.removeAt(i)),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                      ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (i != items.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _section(
            context: context,
            icon: Icons.sticky_note_2_outlined,
            title: _text(context, 'Ghi chú cho khách', 'Customer note'),
            subtitle: _text(context, 'Thông tin tùy chọn sẽ hiển thị cùng báo giá.', 'Optional information shown with this quotation.'),
            child: TextField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _text(context, 'Nhập ghi chú rõ ràng cho khách', 'Add a clear note for the customer'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(context, 'ĐƠN HIỆN TẠI', 'CURRENT BOOKING'),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _money(widget.baseAmount),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+ ${_money(total)} ${_text(context, 'phát sinh', 'additional')}',
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _text(context, 'TỔNG DỰ KIẾN', 'ESTIMATED FINAL TOTAL'),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _money(widget.baseAmount + total),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: sending ? null : _save,
                icon: sending
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(sending
                    ? _text(context, 'Đang lưu...', 'Saving...')
                    : _text(context, 'Lưu bản nháp', 'Save draft')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
