import 'package:flutter/material.dart';
import '../repositories/quotation_repository.dart';

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key, required this.bookingId, required this.technician});
  final String bookingId;
  final bool technician;
  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  final repository = QuotationRepository();
  late Future<List<Map<String, dynamic>>> quotes;
  bool busy = false;

  @override
  void initState() { super.initState(); _reload(); }
  void _reload() { quotes = repository.list(widget.bookingId); }
  void _refresh() { setState(_reload); }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) {
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
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
    floatingActionButton: widget.technician ? FloatingActionButton.extended(
      onPressed: busy ? null : () async {
        final data = await quotes;
        if (!context.mounted) return;
        final hasInitial = data.any((q) => q['quotation_type'] == 'INITIAL');
        final hasApprovedInitial = data.any((q) => q['quotation_type'] == 'INITIAL' && q['status'] == 'ACCEPTED');
        if (hasInitial && !hasApprovedInitial) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Báo giá ban đầu phải được duyệt trước khi tạo báo giá bổ sung.')));
          return;
        }
        final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _QuotationEditor(
          bookingId: widget.bookingId, type: hasInitial ? 'ADDITIONAL' : 'INITIAL', repository: repository,
        )));
        if (created == true) _refresh();
      }, icon: const Icon(Icons.add), label: const Text('Tạo báo giá'),
    ) : null,
    body: FutureBuilder<List<Map<String, dynamic>>>(future: quotes, builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Không tải được báo giá: ${snapshot.error}', textAlign: TextAlign.center),
          TextButton(onPressed: _refresh, child: const Text('Thử lại')),
        ]));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      if (data.isEmpty) {
        return const Center(child: Text('Chưa có báo giá. Booking vẫn sử dụng giá mặc định.'));
      }
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: data.length, itemBuilder: (context, index) {
        final q = data[index];
        final status = q['status']?.toString() ?? '';
        final items = q['items'] is List ? q['items'] as List : const [];
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q['quotation_type'] == 'INITIAL' ? 'Báo giá ban đầu' : 'Báo giá bổ sung #${q['quotation_number']}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5), Text('Trạng thái: $status'),
          if ((q['issue_description']?.toString() ?? '').isNotEmpty) Text('Lý do: ${q['issue_description']}'),
          const Divider(),
          for (final raw in items) Builder(builder: (_) {
            final item = raw as Map;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
              Expanded(child: Text('${item['description']} × ${item['quantity']}')),
              Text('${item['total_price']} đ'),
            ]));
          }),
          const Divider(),
          Text('Tổng cộng: ${q['total_amount']} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (widget.technician && status == 'DRAFT') FilledButton(
            onPressed: busy ? null : () => _run(() => repository.send('${q['id']}')),
            child: const Text('Gửi báo giá'),
          ),
          if (!widget.technician && status == 'PENDING') Row(children: [
            OutlinedButton(onPressed: busy ? null : () => _run(() => repository.respond('${q['id']}', 'REJECTED')), child: const Text('Từ chối')),
            const SizedBox(width: 12),
            FilledButton(onPressed: busy ? null : () => _run(() => repository.respond('${q['id']}', 'ACCEPTED')), child: const Text('Chấp nhận')),
          ]),
        ])));
      });
    }),
  );
}

class _QuotationEditor extends StatefulWidget {
  const _QuotationEditor({required this.bookingId, required this.type, required this.repository});
  final String bookingId;
  final String type;
  final QuotationRepository repository;
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
  num get total => items.fold<num>(0, (sum, item) => sum + (item['quantity'] as num) * (item['unitPrice'] as num));

  @override
  void dispose() { reason.dispose(); note.dispose(); description.dispose(); quantity.dispose(); unitPrice.dispose(); super.dispose(); }

  void _add() {
    final q = num.tryParse(quantity.text);
    final p = num.tryParse(unitPrice.text);
    if (description.text.trim().isEmpty || q == null || q <= 0 || p == null || p < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập mô tả, số lượng và đơn giá hợp lệ.')));
      return;
    }
    setState(() => items.add({'itemType': 'LABOR', 'description': description.text.trim(),
      'quantity': q, 'unit': 'lần', 'unitPrice': p, 'discountAmount': 0}));
    description.clear(); quantity.text = '1'; unitPrice.clear();
  }

  Future<void> _save() async {
    if (items.isEmpty || (widget.type == 'ADDITIONAL' && reason.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần có hạng mục và lý do báo giá bổ sung (nếu có).')));
      return;
    }
    setState(() => sending = true);
    try {
      await widget.repository.create(widget.bookingId, type: widget.type, items: items,
        issueDescription: reason.text.trim(), note: note.text.trim());
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.type == 'INITIAL' ? 'Create Quotation' : 'Additional Quotation')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.type == 'ADDITIONAL') TextField(controller: reason, maxLines: 2, decoration: const InputDecoration(labelText: 'Lý do phát sinh')),
      const Text('Công việc / dịch vụ', style: TextStyle(fontWeight: FontWeight.bold)),
      TextField(controller: description, decoration: const InputDecoration(labelText: 'Tên công việc')),
      Row(children: [
        Expanded(child: TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng'))),
        const SizedBox(width: 12),
        Expanded(child: TextField(controller: unitPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đơn giá (đ)'))),
      ]),
      OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Thêm công việc')),
      for (var i = 0; i < items.length; i++) ListTile(title: Text('${items[i]['description']}'),
        subtitle: Text('${items[i]['quantity']} × ${items[i]['unitPrice']} đ'),
        trailing: IconButton(onPressed: () => setState(() => items.removeAt(i)), icon: const Icon(Icons.delete_outline))),
      const Divider(),
      Text('Tạm tính: $total đ', style: Theme.of(context).textTheme.titleLarge),
      TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Ghi chú cho Customer')),
      const SizedBox(height: 16),
      FilledButton(onPressed: sending ? null : _save, child: const Text('Lưu báo giá nháp')),
    ]),
  );
}
