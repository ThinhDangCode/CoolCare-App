import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../repositories/technician_wallet_repository.dart';
import 'technician_withdrawal_history_page.dart';

// ============================================================
// HELPERS
// ============================================================

String settlementMoney(BuildContext context, Object? value) {
  final amount = (num.tryParse('$value') ?? 0).round();
  final vi = Localizations.localeOf(context).languageCode == 'vi';
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => vi ? '.' : ',',
  );
  return '$sign$digits ₫';
}

String settlementDate(Object? raw) {
  final date = DateTime.tryParse('$raw')?.toLocal();
  if (date == null) return '';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

num walletNumber(Object? value) =>
    num.tryParse('$value') ?? 0;

bool walletVietnamese(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'vi';

String walletText(
    BuildContext context,
    String vietnamese,
    String english,
    ) =>
    walletVietnamese(context) ? vietnamese : english;

String walletStatus(BuildContext context, Object? raw) {
  switch ('$raw') {
    case 'SUCCESS':
    case '2':
      return walletText(context, 'Thành công', 'Successful');
    case 'PENDING':
    case '0':
      return walletText(context, 'Đang chờ', 'Pending');
    case 'PROCESSING':
    case '1':
      return walletText(context, 'Đang xử lý', 'Processing');
    case 'FAILED':
    case '3':
      return walletText(context, 'Thất bại', 'Failed');
    case 'CANCELLED':
    case '4':
      return walletText(context, 'Đã hủy', 'Cancelled');
    default:
      return '$raw';
  }
}

String walletTransactionType(Object? raw) {
  switch ('$raw') {
    case '0':
    case 'CASH_SETTLEMENT':
      return 'CASH_SETTLEMENT';
    case '1':
    case 'ONLINE_EARNING':
      return 'ONLINE_EARNING';
    case '2':
    case 'TOP_UP':
      return 'TOP_UP';
    case '3':
    case 'WITHDRAWAL':
      return 'WITHDRAWAL';
    case '4':
    case 'ADJUSTMENT':
      return 'ADJUSTMENT';
    default:
      return '$raw';
  }
}

String walletTransactionTitle(
    BuildContext context,
    String type,
    ) {
  switch (type) {
    case 'CASH_SETTLEMENT':
      return walletText(
        context,
        'Đối soát tiền mặt',
        'Cash settlement',
      );
    case 'ONLINE_EARNING':
      return walletText(
        context,
        'Thu nhập trực tuyến',
        'Online earnings',
      );
    case 'TOP_UP':
      return walletText(context, 'Nạp tiền', 'Top-up');
    case 'WITHDRAWAL':
      return walletText(context, 'Rút tiền', 'Withdrawal');
    default:
      return walletText(context, 'Điều chỉnh', 'Adjustment');
  }
}

IconData walletTransactionIcon(String type) {
  switch (type) {
    case 'CASH_SETTLEMENT':
      return Icons.payments_outlined;
    case 'ONLINE_EARNING':
      return Icons.account_balance_wallet_outlined;
    case 'TOP_UP':
      return Icons.add_circle_outline;
    case 'WITHDRAWAL':
      return Icons.arrow_upward;
    default:
      return Icons.tune;
  }
}

// ============================================================
// SHARED UI COMPONENTS
// ============================================================

class WalletSectionTitle extends StatelessWidget {
  const WalletSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class WalletMetricCard extends StatelessWidget {
  const WalletMetricCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final Object? amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: CoolCareColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            settlementMoney(context, amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({
    super.key,
    required this.transaction,
  });

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final type = walletTransactionType(
      transaction['transaction_type'],
    );
    final amount = walletNumber(transaction['amount']);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: CircleAvatar(
        backgroundColor:
        CoolCareColors.primary.withValues(alpha: 0.09),
        child: Icon(
          walletTransactionIcon(type),
          color: CoolCareColors.primary,
          size: 21,
        ),
      ),
      title: Text(
        walletTransactionTitle(context, type),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        settlementDate(transaction['created_at']),
        style: TextStyle(
          fontSize: 11,
          color: context.appMuted,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${amount > 0 ? '+' : ''}'
                '${settlementMoney(context, amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: amount < 0
                  ? Colors.redAccent
                  : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            settlementMoney(
              context,
              transaction['balance_after'],
            ),
            style: TextStyle(
              fontSize: 10,
              color: context.appMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 1 - SETTLEMENT WALLET
// ============================================================

class TechnicianWalletPage extends StatefulWidget {
  const TechnicianWalletPage({super.key});

  @override
  State<TechnicianWalletPage> createState() =>
      _TechnicianWalletPageState();
}

class _TechnicianWalletPageState
    extends State<TechnicianWalletPage> {
  final TechnicianWalletRepository _repository =
  TechnicianWalletRepository();

  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _topups = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _repository.overview(),
        _repository.transactions(),
        _repository.topups(),
      ]);

      if (!mounted) return;

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _transactions =
        results[1] as List<Map<String, dynamic>>;
        _topups = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openTopup() async {
    final balance = walletNumber(
      (_overview?['balance'] as Map?)?['settlement_balance'],
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianTopupPage(
          repository: _repository,
          currentBalance: balance,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  Future<void> _openWithdraw() async {
    final balance = walletNumber(
      (_overview?['balance'] as Map?)?['available_balance'],
    );
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TechnicianWithdrawPage(
        repository: _repository, availableBalance: balance,
      ),
    ));
    if (mounted) await _refresh();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianWalletHistoryPage(
          transactions: _transactions,
          topups: _topups,
          repository: _repository,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  void _openDetails() {
    if (_overview == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianSettlementDetailsPage(
          overview: _overview!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        _overview?['balance'] as Map<String, dynamic>? ?? {};
    final earnings =
        _overview?['earnings'] as Map<String, dynamic>? ?? {};
    final movements =
        _overview?['movements'] as Map<String, dynamic>? ?? {};

    final settlementBalance =
    walletNumber(balance['settlement_balance']);

    final recentTransactions =
    _transactions.take(4).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('settlementWalletTitle'),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: walletText(
                  context,
                  'Làm mới',
                  'Refresh',
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 8),
                    Text(context.tr('settlementLoadError')),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: Text(context.tr('tryAgain')),
                    ),
                  ],
                ),
              ),
            ),

          if (_loading && _overview == null)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          if (_overview != null) ...[
            // MAIN BALANCE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CoolCareColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('settlementBalance'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    settlementMoney(
                      context,
                      settlementBalance,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.13,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          settlementBalance < 0
                              ? Icons.info_outline
                              : settlementBalance > 0
                              ? Icons.check_circle_outline
                              : Icons.verified_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            settlementBalance < 0
                                ? walletText(
                              context,
                              'Bạn cần thanh toán '
                                  '${settlementMoney(context, -settlementBalance)} '
                                  'cho CoolCare.',
                              'You owe CoolCare '
                                  '${settlementMoney(context, -settlementBalance)}.',
                            )
                                : settlementBalance > 0
                                ? walletText(
                              context,
                              'CoolCare đang giữ '
                                  '${settlementMoney(context, settlementBalance)} '
                                  'cần trả cho bạn.',
                              'CoolCare owes you '
                                  '${settlementMoney(context, settlementBalance)}.',
                            )
                                : walletText(
                              context,
                              'Bạn đã đối soát xong.',
                              'Your balance is settled.',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // PRIMARY ACTION
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _openTopup,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  settlementBalance < 0
                      ? walletText(
                    context,
                    'Nạp tiền thanh toán công nợ',
                    'Top up to settle debt',
                  )
                      : context.tr('settlementTopup'),
                ),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openWithdraw,
                icon: const Icon(Icons.arrow_upward),
                label: Text(walletText(context, 'Rút tiền mô phỏng', 'Simulated withdrawal')),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TechnicianWithdrawalHistoryPage(
                      repository: _repository,
                    ),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: Text(walletText(
                  context,
                  'Lịch sử rút tiền',
                  'Withdrawal history',
                )),
              ),
            ),

            const SizedBox(height: 25),

            // EARNINGS OVERVIEW
            WalletSectionTitle(
              title: context.tr('settlementEarnings'),
              action: walletText(
                context,
                'Chi tiết',
                'Details',
              ),
              onAction: _openDetails,
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                WalletMetricCard(
                  label: context.tr(
                    'settlementOnlineEarnings',
                  ),
                  amount: earnings['online_earning'],
                  icon: Icons.account_balance_wallet_outlined,
                ),
                WalletMetricCard(
                  label: context.tr(
                    'settlementCashCollected',
                  ),
                  amount: earnings['cash_collected'],
                  icon: Icons.payments_outlined,
                ),
                WalletMetricCard(
                  label: context.tr(
                    'settlementCommission',
                  ),
                  amount: earnings['platform_commission'],
                  icon: Icons.percent,
                ),
                WalletMetricCard(
                  label: context.tr(
                    'settlementTopupTotal',
                  ),
                  amount: movements['total_topup'],
                  icon: Icons.add_circle_outline,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // RECENT TRANSACTIONS
            WalletSectionTitle(
              title: walletText(
                context,
                'Giao dịch gần đây',
                'Recent transactions',
              ),
              action: walletText(
                context,
                'Xem tất cả',
                'View all',
              ),
              onAction: _openHistory,
            ),
            const SizedBox(height: 6),

            if (recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                ),
                child: Center(
                  child: Text(
                    context.tr('settlementEmptyHistory'),
                    style: TextStyle(
                      color: context.appMuted,
                    ),
                  ),
                ),
              )
            else
              ...recentTransactions.map(
                    (transaction) => WalletTransactionTile(
                  transaction: transaction,
                ),
              ),

            const SizedBox(height: 12),

            if (_topups.any((topup) =>
                ['PENDING', 'PROCESSING', '0', '1'].contains('${topup['status']}'))) ...[
              const Divider(),
              WalletSectionTitle(
                title: walletText(context, 'Giao dịch nạp đang xử lý', 'Pending top-ups'),
              ),
              ..._topups
                  .where((topup) => ['PENDING', 'PROCESSING', '0', '1']
                      .contains('${topup['status']}'))
                  .map((topup) => ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(settlementMoney(context, topup['amount'])),
                    subtitle: Text(
                      '${topup['method']} · ${walletStatus(context, topup['status'])}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => TechnicianTopupCheckoutPage(
                          repository: _repository,
                          topup: {
                            'topupId': topup['id'],
                            'topupCode': topup['topup_code'],
                            'amount': topup['amount'],
                            'method': topup['method'],
                            'status': topup['status'],
                          },
                        ),
                      ));
                      if (mounted) await _refresh();
                    },
                  )),
            ],

          ],

          if (_loading && _overview != null)
            const LinearProgressIndicator(),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 2 - TRANSACTION HISTORY
// ============================================================

class TechnicianWalletHistoryPage extends StatefulWidget {
  const TechnicianWalletHistoryPage({
    super.key,
    required this.transactions,
    required this.topups,
    required this.repository,
  });

  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> topups;
  final TechnicianWalletRepository repository;

  @override
  State<TechnicianWalletHistoryPage> createState() =>
      _TechnicianWalletHistoryPageState();
}

class _TechnicianWalletHistoryPageState
    extends State<TechnicianWalletHistoryPage> {
  int _filter = 0;

  final _types = const [
    'ALL',
    'CASH_SETTLEMENT',
    'ONLINE_EARNING',
    'TOP_UP',
    'WITHDRAWAL',
    'ADJUSTMENT',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.transactions.where((tx) {
      if (_filter == 0) return true;
      return walletTransactionType(
        tx['transaction_type'],
      ) ==
          _types[_filter];
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settlementHistory')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            walletText(
              context,
              'Theo dõi các khoản tiền vào và ra '
                  'trong ví đối soát.',
              'Track incoming and outgoing '
                  'settlement transactions.',
            ),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_types.length, (index) {
                final labels = [
                  context.tr('settlementAll'),
                  context.tr('settlementCashMovement'),
                  context.tr('settlementOnlineMovement'),
                  context.tr('settlementTopup'),
                  context.tr('settlementWithdrawn'),
                  context.tr('settlementAdjustment'),
                ];

                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(labels[index]),
                    selected: _filter == index,
                    onSelected: (_) {
                      setState(() => _filter = index);
                    },
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  context.tr('settlementEmptyHistory'),
                ),
              ),
            )
          else
            ...filtered.map(
                  (tx) => WalletTransactionTile(
                transaction: tx,
              ),
            ),

          const SizedBox(height: 25),

          // TOPUP ATTEMPTS INCLUDE UNSUCCESSFUL ATTEMPTS
          WalletSectionTitle(
            title: walletText(
              context,
              'Lịch sử yêu cầu nạp tiền',
              'Top-up attempts',
            ),
          ),

          Text(
            walletText(
              context,
              'Bao gồm cả giao dịch đang chờ '
                  'hoặc chưa thành công.',
              'Includes pending and unsuccessful '
                  'payment attempts.',
            ),
            style: TextStyle(
              fontSize: 11,
              color: context.appMuted,
            ),
          ),

          const SizedBox(height: 8),

          if (widget.topups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                context.tr('settlementNoTopups'),
              ),
            )
          else
            ...widget.topups.map(
                  (topup) => ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add),
                ),
                title: Text(
                  '${topup['method']} · '
                      '${settlementMoney(context, topup['amount'])}',
                ),
                subtitle: Text(
                  settlementDate(topup['created_at']),
                ),
                trailing: Text(
                  walletStatus(context, topup['status']),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TechnicianTopupCheckoutPage(
                            repository: widget.repository,
                            topup: {
                              'topupId': topup['id'],
                              'topupCode': topup['topup_code'],
                              'amount': topup['amount'],
                              'method': topup['method'],
                              'status': topup['status'],
                            },
                          ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 3 - SETTLEMENT DETAILS
// ============================================================

class TechnicianSettlementDetailsPage extends StatefulWidget {
  const TechnicianSettlementDetailsPage({super.key, required this.overview});
  final Map<String, dynamic> overview;

  @override
  State<TechnicianSettlementDetailsPage> createState() =>
      _TechnicianSettlementDetailsPageState();
}

class _TechnicianSettlementDetailsPageState
    extends State<TechnicianSettlementDetailsPage> {
  final _repository = TechnicianWalletRepository();
  String _period = 'month';
  DateTimeRange? _customRange;
  Map<String, dynamic>? _filtered;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  DateTimeRange _rangeFor(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'today':
        return DateTimeRange(start: today, end: today);
      case 'week':
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      case 'custom':
        return _customRange ?? DateTimeRange(start: today, end: today);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
    }
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_requestId;
    final range = _rangeFor(_period);
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repository.overview(fromDate: _date(range.start), toDate: _date(range.end));
      if (!mounted || request != _requestId) return;
      setState(() { _filtered = result; _loading = false; });
    } catch (error) {
      if (!mounted || request != _requestId) return;
      setState(() { _loading = false; _error = error.toString(); });
    }
  }

  Widget _detailRow(String label, Object? amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Text(settlementMoney(context, amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final balance = widget.overview['balance'] as Map<String, dynamic>? ?? {};
    final data = _filtered ?? widget.overview;
    final earnings = data['earnings'] as Map<String, dynamic>? ?? {};
    final movements = data['movements'] as Map<String, dynamic>? ?? {};
    final weekly = (widget.overview['settlements'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final range = _rangeFor(_period);
    final vi = walletVietnamese(context);

    return Scaffold(
      appBar: AppBar(title: Text(walletText(context, 'Thu nhập & Đối soát', 'Earnings & Settlement'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            WalletSectionTitle(title: walletText(context, 'Số dư hiện tại', 'Current balance')),
            const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
              _detailRow(context.tr('settlementBalance'), balance['settlement_balance']),
              _detailRow(context.tr('settlementAvailable'), balance['available_balance']),
              _detailRow(context.tr('settlementReserved'), balance['reserved_amount']),
            ]))),
            const SizedBox(height: 20),
            WalletSectionTitle(title: walletText(context, 'Thống kê theo thời gian', 'Statistics by date')),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final entry in [
                ('today', vi ? 'Hôm nay' : 'Today'),
                ('week', vi ? '7 ngày' : '7 days'),
                ('month', vi ? 'Tháng này' : 'This month'),
                ('custom', vi ? 'Tùy chọn' : 'Custom'),
              ])
                ChoiceChip(label: Text(entry.$2), selected: _period == entry.$1,
                  onSelected: (_) async {
                    if (entry.$1 == 'custom') {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _customRange ?? _rangeFor('month'),
                      );
                      if (picked == null || !mounted) return;
                      _customRange = picked;
                    }
                    setState(() => _period = entry.$1);
                    await _load();
                  }),
            ]),
            const SizedBox(height: 10),
            Text('${_date(range.start)} → ${_date(range.end)}',
              style: TextStyle(color: context.appMuted, fontSize: 12)),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              TextButton(onPressed: _load, child: Text(context.tr('tryAgain'))),
            ],
            const SizedBox(height: 20),
            WalletSectionTitle(title: context.tr('settlementEarnings')),
            Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
              _detailRow(context.tr('settlementOnlineEarnings'), earnings['online_earning']),
              _detailRow(context.tr('settlementCashCollected'), earnings['cash_collected']),
              _detailRow(context.tr('settlementCommission'), earnings['platform_commission']),
              _detailRow(context.tr('settlementPlatformDiscount'), earnings['platform_discount']),
              _detailRow(context.tr('settlementTotalEarnings'), earnings['total_earnings']),
            ]))),
            const SizedBox(height: 20),
            WalletSectionTitle(title: walletText(context, 'Biến động số dư', 'Balance movements')),
            Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
              _detailRow(context.tr('settlementTopupTotal'), movements['total_topup']),
              _detailRow(context.tr('settlementWithdrawn'), movements['total_withdrawal']),
              _detailRow(context.tr('settlementNetAdjustments'), movements['net_adjustments']),
            ]))),
            const SizedBox(height: 22),
            WalletSectionTitle(title: context.tr('settlementWeekly')),
            const SizedBox(height: 8),
            if (weekly.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(context.tr('settlementNoWeekly')),
              )
            else
              ...weekly.map((period) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(
                    '${settlementDate(period['period_start']).split(' ').first}'
                    ' – ${settlementDate(period['period_end']).split(' ').first}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${context.tr('settlementClosing')}: '
                    '${settlementMoney(context, period['closing_balance'])}',
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    _detailRow(context.tr('settlementOpening'), period['opening_balance']),
                    _detailRow(context.tr('settlementCashMovement'), period['total_cash_settlement']),
                    _detailRow(context.tr('settlementOnlineEarnings'), period['total_online_earning']),
                    _detailRow(context.tr('settlementTopupTotal'), period['total_topup']),
                    _detailRow(context.tr('settlementWithdrawn'), period['total_withdrawal']),
                    _detailRow(context.tr('settlementNetAdjustments'), period['total_adjustment']),
                    const Divider(),
                    _detailRow(context.tr('settlementOutstandingDebt'), period['debt_remaining_amount']),
                  ],
                ),
              )),
            const SizedBox(height: 12),
            Text(walletText(context,
              'Số dư là số liệu hiện tại; thu nhập và biến động được lọc theo ngày phát sinh.',
              'Balances are current; earnings and movements are filtered by transaction date.'),
              style: TextStyle(color: context.appMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 4 - TOP UP
// ============================================================

class TechnicianTopupPage extends StatefulWidget {
  const TechnicianTopupPage({
    super.key,
    required this.repository,
    this.currentBalance = 0,
  });

  final TechnicianWalletRepository repository;
  final num currentBalance;

  @override
  State<TechnicianTopupPage> createState() =>
      _TechnicianTopupPageState();
}

class _TechnicianTopupPageState
    extends State<TechnicianTopupPage> {
  late final TextEditingController _amountController;

  String _method = 'VNPAY';
  String? _key;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    final debt = widget.currentBalance < 0
        ? -widget.currentBalance
        : 0;

    _amountController = TextEditingController(
      text: debt >= 10000 && debt <= 50000000
          ? debt.ceil().toString()
          : '200000',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;

    final text = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${text.substring(0, 8)}-'
        '${text.substring(8, 12)}-'
        '${text.substring(12, 16)}-'
        '${text.substring(16, 20)}-'
        '${text.substring(20)}';
  }

  void _changeAmount(int amount) {
    _amountController.text = '$amount';
    _key = null;
  }

  Future<void> _submit() async {
    if (_busy) return;

    final amount = int.tryParse(
      _amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      ),
    );

    if (amount == null ||
        amount < 10000 ||
        amount > 50000000) {
      setState(() {
        _error = context.tr('settlementInvalidAmount');
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    _key ??= _newKey();

    try {
      final result = await widget.repository.createTopup(
        amount: amount,
        method: _method,
        idempotencyKey: _key!,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TechnicianTopupCheckoutPage(
            repository: widget.repository,
            topup: result,
          ),
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.currentBalance < 0
        ? -widget.currentBalance
        : 0;

    final amount = int.tryParse(
      _amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      ),
    ) ??
        0;

    final projectedBalance =
        widget.currentBalance + amount;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settlementTopup')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (debt > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.orange.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        walletText(
                          context,
                          'Bạn đang nợ CoolCare '
                              '${settlementMoney(context, debt)}. '
                              'Bạn có thể nạp một phần hoặc toàn bộ.',
                          'You owe CoolCare '
                              '${settlementMoney(context, debt)}. '
                              'You can top up partially or in full.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            Text(
              context.tr('settlementAmount'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                setState(() {
                  _key = null;
                });
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: 'VND',
                hintText:
                context.tr('settlementEnterAmount'),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (debt >= 10000 && debt <= 50000000)
                  ActionChip(
                    avatar: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      walletText(
                        context,
                        'Nạp đủ công nợ',
                        'Settle debt',
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _changeAmount(debt.ceil());
                      });
                    },
                  ),
                for (final value in [
                  100000,
                  200000,
                  500000,
                  1000000,
                ])
                  ActionChip(
                    label: Text(
                      settlementMoney(context, value),
                    ),
                    onPressed: () {
                      setState(() {
                        _changeAmount(value);
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: 26),

            Text(
              context.tr('settlementPaymentMethod'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            RadioGroup<String>(
              groupValue: _method,
              onChanged: (value) {
                setState(() {
                  _method = value!;
                  _key = null;
                });
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('VNPay'),
                    subtitle: Text(walletText(
                      context,
                      'Thanh toán qua VNPay',
                      'Pay with VNPay',
                    )),
                    value: 'VNPAY',
                  ),
                  RadioListTile<String>(
                    title: const Text('ZaloPay'),
                    subtitle: Text(walletText(
                      context,
                      'Thanh toán qua ZaloPay',
                      'Pay with ZaloPay',
                    )),
                    value: 'ZALOPAY',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // BALANCE PREVIEW
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.appBorder,
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    context,
                    walletText(
                      context,
                      'Số dư hiện tại',
                      'Current balance',
                    ),
                    widget.currentBalance,
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    context,
                    context.tr('settlementTopup'),
                    amount,
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    context,
                    walletText(
                      context,
                      'Số dư dự kiến sau khi nạp',
                      'Estimated balance after top-up',
                    ),
                    projectedBalance,
                    strong: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              walletText(
                context,
                'Số dư chỉ được cập nhật khi hệ thống '
                    'xác nhận thanh toán thành công.',
                'Your balance updates only after '
                    'payment is confirmed.',
              ),
              style: TextStyle(
                fontSize: 12,
                color: context.appMuted,
                height: 1.4,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ],

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  context.tr('settlementContinue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
      BuildContext context,
      String title,
      Object? value, {
        bool strong = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          settlementMoney(context, value),
          style: TextStyle(
            fontSize: strong ? 16 : 13,
            fontWeight:
            strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCREEN 5 - TOP UP CHECKOUT / PAYMENT STATUS
// ============================================================

class TechnicianTopupCheckoutPage extends StatefulWidget {
  const TechnicianTopupCheckoutPage({
    super.key,
    required this.repository,
    required this.topup,
  });

  final TechnicianWalletRepository repository;
  final Map<String, dynamic> topup;

  @override
  State<TechnicianTopupCheckoutPage> createState() =>
      _TechnicianTopupCheckoutPageState();
}

class _TechnicianTopupCheckoutPageState
    extends State<TechnicianTopupCheckoutPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  late Map<String, dynamic> _topup;

  bool _loading = false;
  String? _error;

  String get _status => '${_topup['status']}';

  bool get _success =>
      _status == 'SUCCESS' || _status == '2';

  bool get _failed =>
      ['FAILED', 'CANCELLED', '3', '4']
          .contains(_status);

  bool get _finished => _success || _failed;

  @override
  void initState() {
    super.initState();

    _topup = Map<String, dynamic>.from(widget.topup);

    WidgetsBinding.instance.addObserver(this);

    _timer = Timer.periodic(
      const Duration(seconds: 8),
          (_) {
        if (mounted && !_loading && !_finished) {
          _check();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.resumed &&
        !_loading &&
        !_finished) {
      _check();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check({
    bool reconcile = false,
  }) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = '${_topup['topupId']}';

      final result =
      reconcile && _topup['method'] == 'ZALOPAY'
          ? await widget.repository.reconcile(id)
          : await widget.repository.topupDetail(id);

      if (!mounted) return;

      setState(() {
        _topup = {
          ..._topup,
          ...result,
        };
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = _topup['checkout'];

    final data = checkout is Map
        ? Map<String, dynamic>.from(checkout)
        : <String, dynamic>{};

    final qr = data['qrData']?.toString();
    final url = data['url']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settlementTopupStatus'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 15),

            Text(
              settlementMoney(
                context,
                _topup['amount'],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_topup['method']} · '
                  '${walletStatus(context, _topup['status'])}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 26),

            if (_success) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 76,
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('settlementCredited'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                walletText(
                  context,
                  'Tiền đã được cộng vào số dư đối soát.',
                  'The amount has been credited '
                      'to your settlement balance.',
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_failed) ...[
              const Icon(
                Icons.cancel_outlined,
                color: Colors.redAccent,
                size: 76,
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('settlementNotCredited'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                walletText(
                  context,
                  'Giao dịch chưa được cộng vào ví. '
                      'Bạn có thể quay lại để tạo yêu cầu mới.',
                  'This payment was not credited. '
                      'You can return and try again.',
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    if (qr != null && qr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qr,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      qr == null || qr.isEmpty
                          ? context.tr(
                        'settlementQrUnavailable',
                      )
                          : context.tr(
                        'settlementScanQrHint',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              if (url != null && url.isNotEmpty) ...[
                const SizedBox(height: 14),
                SelectableText(
                  url,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appMuted,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.appBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        walletText(
                          context,
                          'Đang chờ xác nhận thanh toán. '
                              'Không cần nạp lại nếu bạn đã trả tiền.',
                          'Waiting for payment confirmation. '
                              'Do not pay again if you already paid.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _check(reconcile: true),
                icon: const Icon(Icons.sync),
                label: Text(
                  context.tr('settlementCheckStatus'),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],

            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  _success
                      ? walletText(
                    context,
                    'Về ví đối soát',
                    'Back to wallet',
                  )
                      : context.tr('settlementDone'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class TechnicianWithdrawPage extends StatefulWidget {
  const TechnicianWithdrawPage({super.key, required this.repository, required this.availableBalance});
  final TechnicianWalletRepository repository;
  final num availableBalance;
  @override
  State<TechnicianWithdrawPage> createState() => _TechnicianWithdrawPageState();
}

class _TechnicianWithdrawPageState extends State<TechnicianWithdrawPage> {
  final _amount = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();
  bool _busy = false;
  bool _loadingHolder = true;
  String? _error;
  String? _result;
  late final String _requestKey;

  String _newUuid() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final hex = b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
  }

  @override
  void initState() {
    super.initState();
    _requestKey = _newUuid();
    _loadAccountHolder();
  }

  Future<void> _loadAccountHolder() async {
    try {
      final name = await widget.repository.signedInTechnicianName();
      if (!mounted) {
        return;
      }
      final phone = await widget.repository.signedInTechnicianPhone();
      if (!mounted) {
        return;
      }
      setState(() {
        _holder.text = name;
        if (phone.isNotEmpty) _account.text = phone;
        _loadingHolder = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingHolder = false;
          _error = 'Không lấy được tên kỹ thuật viên. Vui lòng đăng nhập lại.';
        });
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose(); _account.dispose(); _holder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _result != null || _loadingHolder) return;
    final amount = int.tryParse(_amount.text.trim());
    final phone = _account.text.trim();
    if (amount == null || amount < 100000 || amount > 50000000 || amount > widget.availableBalance ||
        !RegExp(r'^0[0-9]{9}$').hasMatch(phone) ||
        _holder.text.trim().isEmpty) {
      setState(() => _error = 'Kiểm tra số tiền và số điện thoại.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final data = await widget.repository.createMockWithdrawal(
        amount: amount, bankName: 'ZaloPay',
        accountNumber: _account.text.trim(), accountHolder: _holder.text.trim(),
        idempotencyKey: _requestKey,
      );
      if (!mounted) return;
      setState(() => _result = 'Đã ghi giao dịch mô phỏng ${settlementMoney(context, data['amount'])} trên ví CoolCare. Không có tiền được chuyển sang ZaloPay.');
    } catch (e) {
      if (!mounted) return;
      // Keep the same request key for safe retries after network timeouts.
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Rút tiền mô phỏng')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF078C99),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(settlementMoney(context, widget.availableBalance),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Thử nghiệm rút tiền — không chuyển tiền thật sang ZaloPay.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            onChanged: (_) => setState(() { _error = null; }),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Số tiền rút', hintText: 'Tối thiểu 100.000đ',
              prefixIcon: Icon(Icons.payments_outlined), border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: _account, keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => setState(() { _error = null; }),
            decoration: const InputDecoration(labelText: 'Số điện thoại ZaloPay', hintText: 'Nhập số điện thoại nhận tiền',
              prefixIcon: Icon(Icons.phone_android_outlined), border: OutlineInputBorder())),
          const SizedBox(height: 14),
          TextField(controller: _holder, readOnly: true,
            decoration: InputDecoration(labelText: 'Tên kỹ thuật viên',
              helperText: 'Theo hồ sơ kỹ thuật viên CoolCare',
              hintText: _loadingHolder ? 'Đang tải...' : 'Chưa có tên',
              prefixIcon: const Icon(Icons.person_outline), border: const OutlineInputBorder())),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _withdrawSummaryRow('Số tiền yêu cầu', settlementMoney(context, amount)),
              const SizedBox(height: 10),
              const Divider(height: 24),
              _withdrawSummaryRow('Số tiền mô phỏng', settlementMoney(context, amount), bold: true),
            ]),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 14),
            Text(_result!, style: const TextStyle(color: Color(0xFF078C99), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 22),
          SizedBox(height: 50, child: FilledButton.icon(
            onPressed: _busy || _result != null || _loadingHolder || _holder.text.trim().isEmpty ? null : _submit,
            icon: _busy ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward),
            label: Text(_busy ? 'Đang xử lý...' : _result != null ? 'Đã hoàn tất' : 'Xác nhận giao dịch mô phỏng'),
          )),
          if (_result != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Về ví đối soát')),
          ],
        ],
      ),
    );
  }

  Widget _withdrawSummaryRow(String label, String value, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ]);
}
