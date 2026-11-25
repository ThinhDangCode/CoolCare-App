import 'package:flutter/material.dart';
import '../../../core/localization/language_state.dart';


import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/ac_service_history.dart';
import '../repositories/technician_portal_repository.dart';

String _bi(String vi, String en) => LanguageState.code == 'en' ? en : vi;

class CustomerAcServiceHistoryPage extends StatefulWidget {
  const CustomerAcServiceHistoryPage({
    required this.requestId,
    required this.unitId,
    required this.customerName,
    required this.address,
    required this.repository,
    super.key,
  });

  final String requestId;
  final String unitId;
  final String customerName;
  final String address;
  final TechnicianPortalRepository repository;

  @override
  State<CustomerAcServiceHistoryPage> createState() =>
      _CustomerAcServiceHistoryPageState();
}

class _CustomerAcServiceHistoryPageState
    extends State<CustomerAcServiceHistoryPage> {
  late Future<AcServiceHistory> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<AcServiceHistory> _load() => widget.repository
      .customerAcServiceHistory(widget.requestId, widget.unitId, limit: 50);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _history = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8F9),
    appBar: AppBar(
      toolbarHeight: 58,
      leadingWidth: 52,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 7, bottom: 7),
        child: Material(
          color: const Color(0xFFEAF6F7),
          shape: const CircleBorder(),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 19,
              color: Color(0xFF087F92),
            ),
          ),
        ),
      ),
      titleSpacing: 10,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _bi('Lịch sử dịch vụ máy lạnh', 'AC Service History'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            widget.customerName,
            style: const TextStyle(
              color: Color(0xFF657F8A),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      shape: const Border(bottom: BorderSide(color: Color(0xFFDBE7EB))),
    ),
    body: FutureBuilder<AcServiceHistory>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _HistoryMessage(
            icon: Icons.cloud_off_outlined,
            message: error is ApiException
                ? error.message
                : _bi('Không tải được lịch sử dịch vụ.', 'Unable to load AC service history.'),
            actionLabel: _bi('Thử lại', 'Try again'),
            onAction: _refresh,
          );
        }
        final history = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Text(_bi('Lịch sử đối chiếu theo địa chỉ, hãng và model; có thể gồm nhiều máy giống nhau.', 'History matches address, brand and model; identical AC units may be combined.'))),
              _CustomerAndUnitHeader(
                customerName: widget.customerName,
                address: widget.address,
                unit: history.unit,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _bi('Lịch sử dịch vụ', 'Service Timeline'),
                            style: TextStyle(
                              color: Color(0xFF193943),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${history.pagination.total} ${_bi('lần', 'visits')}',
                          style: const TextStyle(
                            color: Color(0xFF657F8A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (history.items.isEmpty)
                      const _HistoryEmpty()
                    else
                      for (var index = 0; index < history.items.length; index++)
                        _TimelineItem(
                          item: history.items[index],
                          first: index == 0,
                          last: index == history.items.length - 1,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CustomerAndUnitHeader extends StatelessWidget {
  const _CustomerAndUnitHeader({
    required this.customerName,
    required this.address,
    required this.unit,
  });
  final String customerName;
  final String address;
  final AcServiceHistoryUnit unit;

  @override
  Widget build(BuildContext context) {
    final acName = [
      unit.brandName,
      unit.modelName,
    ].where((value) => value?.trim().isNotEmpty == true).join(' ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDBE7EB))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEAF6F7),
                child: Icon(
                  Icons.home_outlined,
                  color: Color(0xFF087F92),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: Color(0xFF193943),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF657F8A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.ac_unit_rounded,
                  size: 20,
                  color: Color(0xFF087F92),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acName.isEmpty ? _bi('Máy lạnh', 'Air conditioner') : acName,
                        style: const TextStyle(
                          color: Color(0xFF193943),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                              if (unit.unitNumber > 0)
                                '${_bi('Máy', 'Unit')} ${unit.unitNumber}',
                              unit.description,
                            ]
                            .where((value) => value?.trim().isNotEmpty == true)
                            .join(' · '),
                        style: const TextStyle(
                          color: Color(0xFF657F8A),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.first,
    required this.last,
  });
  final AcServiceHistoryItem item;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: first
                      ? CoolCareColors.primary
                      : const Color(0xFF657F8A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEAF6F7), width: 2),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFDBE7EB)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: last ? 0 : 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDBE7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _date(item.completedAt),
                        style: const TextStyle(
                          color: Color(0xFF657F8A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _money(item.totalAmount),
                      style: const TextStyle(
                        color: Color(0xFF087F92),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF193943),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('${_bi('Mã đơn', 'Booking code')}: ${item.bookingCode}'),
                Text('${_bi('Ngày hẹn', 'Scheduled date')}: ${_date(item.scheduledAt)}'),
                Text(_bi('Chi phí trên là tổng đơn, không phải riêng máy.', 'Amount above is the booking total, not the individual AC cost.')),
                for (final entry in <String, String?>{
                  _bi('Tình trạng máy', 'AC condition'): item.unitDescription,
                  _bi('Mô tả đơn', 'Booking description'): item.bookingDescription,
                  _bi('Chẩn đoán', 'Diagnosis'): item.diagnosis,
                  _bi('Ghi chú sửa chữa', 'Service notes'): item.serviceNotes,
                }.entries)
                  if (entry.value?.trim().isNotEmpty == true) Text('${entry.key}: ${entry.value}'),
                for (final service in item.services)
                  Text('${service.name}: ${_money(service.unitPrice)}'),
                if (item.additionalWork.isNotEmpty)
                  Text(_bi('Phát sinh toàn đơn', 'Booking-wide additional work')),
                for (final work in item.additionalWork) ...[
                  Text('${work.description}: ${work.quantity} ${work.unit ?? ''} × ${_money(work.unitPrice)}'),
                  if (work.reason?.isNotEmpty == true) Text('${_bi('Lý do', 'Reason')}: ${work.reason}'),
                  if (work.note?.isNotEmpty == true) Text('${_bi('Ghi chú', 'Note')}: ${work.note}'),
                ],
                if (item.additionalWork.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: item.additionalWork
                        .map(
                          (work) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF6F7),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '+ ${work.description} · ${_money(work.totalPrice)}',
                              style: const TextStyle(
                                color: Color(0xFF087F92),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (item.technicianName?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Color(0xFF657F8A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_bi('Kỹ thuật viên', 'Tech')}: ${item.technicianName}',
                        style: const TextStyle(
                          color: Color(0xFF657F8A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDBE7EB)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(
          Icons.history_toggle_off_rounded,
          size: 38,
          color: Color(0xFF8AA0A6),
        ),
        SizedBox(height: 10),
        Text(
          _bi('Chưa có lịch sử dịch vụ', 'No previous service history'),
          style: TextStyle(
            color: Color(0xFF193943),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _bi('Có thể đây là lần đầu máy lạnh được ghi nhận dịch vụ.', 'This may be the first recorded service for this AC.'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF657F8A), fontSize: 12),
        ),
      ],
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: const Color(0xFF8AA0A6)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

String _date(DateTime? value) {
  if (value == null) return _bi('Chưa có ngày', 'Date unavailable');
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

String _money(double value) =>
    '${value.round().toString().replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (_) => ',')} VND';
