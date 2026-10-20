import 'package:flutter/material.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../repositories/quotation_repository.dart';

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
    appBar: AppBar(title: const Text('Báo giá')),
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
                        const SnackBar(
                          content: Text(
                            'Báo giá ban đầu phải được duyệt trước khi tạo báo giá bổ sung.',
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
            label: const Text('Tạo báo giá'),
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
                  'Không tải được báo giá: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: _refresh, child: const Text('Thử lại')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(
            child: Text('Chưa có báo giá. Booking vẫn sử dụng giá mặc định.'),
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
                          ? 'Báo giá ban đầu'
                          : 'Báo giá bổ sung #${q['quotation_number']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text('Trạng thái: $status'),
                    if ((q['issue_description']?.toString() ?? '').isNotEmpty)
                      Text('Lý do: ${q['issue_description']}'),
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
                                Text('${item['total_price']} đ'),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(),
                    Text(
                      'Tổng cộng: ${q['total_amount']} đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.technician && status == 'DRAFT')
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => _run(() => repository.send('${q['id']}')),
                        child: const Text('Gửi báo giá'),
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
                            child: const Text('Từ chối'),
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
                            child: const Text('Chấp nhận'),
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
        const SnackBar(
          content: Text('Nhập mô tả, số lượng và đơn giá hợp lệ.'),
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
        const SnackBar(
          content: Text('Cần có hạng mục và lý do báo giá bổ sung (nếu có).'),
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
    final digits = value.round().toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
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
          isAdditional ? 'Create Additional Quotation' : 'Create Quotation',
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional service quotation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Only enter work that is outside the original service. The approved amount will be added to the current booking total.',
                        style: TextStyle(
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
              title: 'Reason for additional work',
              subtitle:
                  'Explain why this work was not included in the original service.',
              child: TextField(
                controller: reason,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Example: Additional refrigerant is required after inspection',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _section(
            context: context,
            icon: Icons.home_repair_service_outlined,
            title: 'Work details',
            subtitle:
                'Add each additional task with its quantity and unit price.',
            child: Column(
              children: [
                TextField(
                  controller: description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task or service name',
                    hintText: 'Enter the additional work',
                    prefixIcon: Icon(Icons.build_outlined),
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
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers_rounded),
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
                        decoration: const InputDecoration(
                          labelText: 'Unit price',
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
                    label: const Text('Add to quotation'),
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
            title: 'Quotation items',
            subtitle: items.isEmpty
                ? 'No additional work has been added yet.'
                : '${items.length} ${items.length == 1 ? 'item' : 'items'} added',
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
                          'Add at least one item to continue',
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
                                      tooltip: 'Remove item',
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
            title: 'Customer note',
            subtitle:
                'Optional information that will appear with this quotation.',
            child: TextField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a clear note for the customer',
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
                      'CURRENT BOOKING',
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
                      '+ ${_money(total)} additional',
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ESTIMATED FINAL TOTAL',
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
                label: Text(sending ? 'Saving...' : 'Save draft'),
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
