import 'package:flutter/material.dart';

import '../repositories/technician_wallet_repository.dart';
import 'technician_wallet_page.dart' show settlementDate, settlementMoney, walletStatus, walletText;

/// Displays actual withdrawal requests, including unsuccessful attempts.
/// The API currently returns 30 records per page and no total count.
class TechnicianWithdrawalHistoryPage extends StatefulWidget {
  const TechnicianWithdrawalHistoryPage({super.key, required this.repository});

  final TechnicianWalletRepository repository;

  @override
  State<TechnicianWithdrawalHistoryPage> createState() =>
      _TechnicianWithdrawalHistoryPageState();
}

class _TechnicianWithdrawalHistoryPageState
    extends State<TechnicianWithdrawalHistoryPage> {
  static const _pageSize = 30;
  static const _statuses = ['ALL', 'SUCCESS', 'PENDING', 'PROCESSING', 'FAILED', 'CANCELLED'];

  final List<Map<String, dynamic>> _items = [];
  String _filter = 'ALL';
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nextPage = reset ? 1 : _page + 1;
      final rows = await widget.repository.withdrawals(page: nextPage);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(rows);
        _page = nextPage;
        _hasMore = rows.length == _pageSize;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _status(Map<String, dynamic> row) => '${row['status'] ?? ''}'.toUpperCase();

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'SUCCESS': return Colors.green.shade700;
      case 'FAILED': return colors.error;
      case 'CANCELLED': return Colors.grey.shade700;
      default: return Colors.orange.shade800;
    }
  }

  void _showDetails(Map<String, dynamic> row) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vi ? 'Chi tiết rút tiền' : 'Withdrawal details',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 18),
            _detailRow(vi ? 'Số tiền yêu cầu' : 'Requested amount', settlementMoney(context, row['amount'])),
            _detailRow(vi ? 'Phí' : 'Fee', settlementMoney(context, row['fee_amount'])),
            _detailRow(vi ? 'Thực nhận' : 'Net amount', settlementMoney(context, row['net_amount'])),
            _detailRow(vi ? 'Trạng thái' : 'Status', walletStatus(context, row['status'])),
            _detailRow(vi ? 'Phương thức' : 'Method', '${row['bank_name'] ?? '-'}'),
            _detailRow(vi ? 'Số tài khoản' : 'Account', '${row['account_number'] ?? '-'}'),
            _detailRow(vi ? 'Chủ tài khoản' : 'Account holder', '${row['account_holder'] ?? '-'}'),
            _detailRow(vi ? 'Ngày yêu cầu' : 'Requested at', settlementDate(row['initiated_at'])),
            if (row['processed_at'] != null)
              _detailRow(vi ? 'Ngày xử lý' : 'Processed at', settlementDate(row['processed_at'])),
            if (row['paid_at'] != null)
              _detailRow(vi ? 'Ngày hoàn thành' : 'Paid at', settlementDate(row['paid_at'])),
            if ('${row['payout_reference'] ?? ''}'.isNotEmpty)
              _detailRow(vi ? 'Mã tham chiếu' : 'Reference', '${row['payout_reference']}'),
            const SizedBox(height: 8),
            Text(vi ? 'Lưu ý: Chức năng rút tiền hiện là mô phỏng, không chuyển tiền thật.'
                : 'Note: Withdrawals are currently simulated; no real payout occurs.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 2, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final colors = Theme.of(context).colorScheme;
    final visible = _items.where((row) => _filter == 'ALL' || _status(row) == _filter).toList();
    final totalSuccess = _items.where((row) => _status(row) == 'SUCCESS')
        .fold<num>(0, (sum, row) => sum + (num.tryParse('${row['amount']}') ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(vi ? 'Lịch sử rút tiền' : 'Withdrawal History')),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: colors.primary,
            child: Padding(padding: const EdgeInsets.all(20), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vi ? 'Đã rút thành công (dữ liệu đã tải)' : 'Successful withdrawals (loaded records)',
                    style: TextStyle(color: colors.onPrimary.withValues(alpha: .85))),
                const SizedBox(height: 8),
                Text(settlementMoney(context, totalSuccess),
                    style: TextStyle(color: colors.onPrimary, fontSize: 27, fontWeight: FontWeight.bold)),
              ],
            )),
          ),
          const SizedBox(height: 18),
          Text(vi ? 'Danh sách yêu cầu rút tiền' : 'Withdrawal requests',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final status in _statuses)
              Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(
                label: Text(status == 'ALL' ? (vi ? 'Tất cả' : 'All') : walletStatus(context, status)),
                selected: _filter == status,
                onSelected: (_) => setState(() => _filter = status),
              )),
          ])),
          const SizedBox(height: 12),
          if (visible.isEmpty && !_loading)
            Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Center(
              child: Text(vi ? 'Không có yêu cầu rút tiền phù hợp.' : 'No matching withdrawals.'),
            )),
          for (final row in visible)
            Card(child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.north_east, color: colors.primary)),
              title: Text(settlementMoney(context, row['amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${row['bank_name'] ?? 'ZaloPay'} · ${settlementDate(row['initiated_at'])}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                children: [Text(walletStatus(context, row['status']),
                    style: TextStyle(color: _statusColor(_status(row), colors), fontSize: 12,
                        fontWeight: FontWeight.w600)), const Icon(Icons.chevron_right, size: 18)]),
              onTap: () => _showDetails(row),
            )),
          if (_error != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.error)),
              TextButton(onPressed: _loading ? null : () => _load(reset: _page == 0),
                  child: Text(vi ? 'Thử lại' : 'Retry')),
            ])),
          if (_loading)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          if (_hasMore && !_loading && _error == null)
            Center(child: OutlinedButton.icon(
              onPressed: () => _load(), icon: const Icon(Icons.expand_more),
              label: Text(vi ? 'Tải thêm' : 'Load more'),
            )),
          const SizedBox(height: 16),
          Text(vi ? 'Bộ lọc áp dụng cho các trang đã tải. Kéo xuống để cập nhật.'
              : 'Filters apply to loaded pages. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
