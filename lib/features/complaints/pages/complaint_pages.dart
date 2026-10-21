import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../booking/models/my_booking.dart';
import '../../booking/repositories/my_bookings_repository.dart';
import '../models/customer_complaint.dart';
import '../repositories/complaint_repository.dart';

String _t(BuildContext context, String vi, String en) =>
    Localizations.localeOf(context).languageCode == 'vi' ? vi : en;

String _date(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _loadErrorMessage(BuildContext context, Object? error) {
  if (error is ApiException) return error.message;
  if (error is StateError) {
    return _t(
      context,
      'Phiên đăng nhập không khả dụng. Hãy đăng xuất rồi đăng nhập lại.',
      'Your sign-in session is unavailable. Sign out and sign in again.',
    );
  }
  if (error is FormatException) {
    return _t(
      context,
      'Dữ liệu máy chủ trả về không đúng định dạng. Hãy cập nhật backend rồi thử lại.',
      'The server returned an unexpected response. Update the backend and try again.',
    );
  }
  return _t(
    context,
    'Không thể kết nối đến máy chủ. Hãy kiểm tra backend và thử lại.',
    'Cannot connect to the server. Check that the backend is running and try again.',
  );
}

String _type(BuildContext context, String value) => switch (value) {
  'SERVICE' => _t(context, 'Dịch vụ', 'Service'),
  'TECHNICIAN' => _t(context, 'Nhân viên', 'Technician'),
  'PAYMENT' => _t(context, 'Thanh toán', 'Payment'),
  _ => _t(context, 'Khác', 'Other'),
};

String _status(BuildContext context, String value) => switch (value) {
  'OPEN' => _t(context, 'Đã tiếp nhận', 'Received'),
  'IN_PROGRESS' => _t(context, 'Đang xử lý', 'In progress'),
  'RESOLVED' => _t(context, 'Đã giải quyết', 'Resolved'),
  'REJECTED' => _t(context, 'Không chấp nhận', 'Rejected'),
  'CLOSED' => _t(context, 'Đã đóng', 'Closed'),
  _ => value,
};

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});
  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  final _repository = ComplaintRepository();
  final List<CustomerComplaint> _items = [];
  String _filter = 'ALL';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;
  int _page = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _page = 0;
        _items.clear();
      });
    }
    try {
      final result = await _repository.list(status: _filter, page: 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final result = await _repository.list(status: _filter, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SubmitComplaintPage()),
    );
    if (created == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      title: Text(_t(context, 'Khiếu nại của tôi', 'My Complaints')),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add_comment_outlined),
      label: Text(_t(context, 'Gửi khiếu nại', 'New complaint')),
    ),
    body: Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            children:
                ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED']
                    .map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            value == 'ALL'
                                ? _t(context, 'Tất cả', 'All')
                                : _status(context, value),
                          ),
                          selected: _filter == value,
                          onSelected: (_) {
                            if (_filter == value) return;
                            setState(() => _filter = value);
                            _reload();
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        if (!_loading && _error == null && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t(context, '$_total khiếu nại', '$_total complaints'),
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                ? _MessageList(
                    icon: Icons.cloud_off_outlined,
                    title: _t(
                      context,
                      'Không thể tải khiếu nại',
                      'Unable to load complaints',
                    ),
                    subtitle: _loadErrorMessage(context, _error),
                    action: _reload,
                    actionLabel: _t(context, 'Thử lại', 'Retry'),
                  )
                : _items.isEmpty
                ? _MessageList(
                    icon: Icons.mark_chat_unread_outlined,
                    title: _t(
                      context,
                      'Bạn chưa có khiếu nại nào',
                      'You have no complaints yet',
                    ),
                    subtitle: _t(
                      context,
                      'Khi cần hỗ trợ, hãy gửi khiếu nại và chúng tôi sẽ phản hồi tại đây.',
                      'Submit a complaint when you need help. Our response will appear here.',
                    ),
                    action: _create,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                    itemCount:
                        _items.length + (_hasMore || _error != null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      if (index >= _items.length) {
                        if (_error != null) {
                          return _InlineLoadError(
                            message: _loadErrorMessage(context, _error),
                            onRetry: _loadMore,
                          );
                        }
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: _loadingMore ? null : _loadMore,
                              icon: _loadingMore
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more_rounded),
                              label: Text(
                                _loadingMore
                                    ? _t(context, 'Đang tải...', 'Loading...')
                                    : _t(context, 'Tải thêm', 'Load more'),
                              ),
                            ),
                          ),
                        );
                      }
                      return _ComplaintCard(
                        complaint: _items[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ComplaintDetailPage(id: _items[index].id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    ),
  );
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMuted),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_t(context, 'Thử tải lại', 'Retry loading')),
        ),
      ],
    ),
  );
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onTap});
  final CustomerComplaint complaint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(value: complaint.status),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '${_type(context, complaint.type)} · #${complaint.bookingCode}',
              style: TextStyle(color: context.appMuted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              '${complaint.code} · ${_date(complaint.createdAt)}',
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class ComplaintDetailPage extends StatefulWidget {
  const ComplaintDetailPage({required this.id, super.key});
  final String id;
  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  late Future<CustomerComplaint> _future;
  @override
  void initState() {
    super.initState();
    _future = ComplaintRepository().get(widget.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      title: Text(_t(context, 'Chi tiết khiếu nại', 'Complaint details')),
    ),
    body: FutureBuilder<CustomerComplaint>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageList(
            icon: Icons.error_outline,
            title: _t(
              context,
              'Không thể tải chi tiết',
              'Unable to load details',
            ),
            subtitle: _loadErrorMessage(context, snapshot.error),
            action: () =>
                setState(() => _future = ComplaintRepository().get(widget.id)),
            actionLabel: _t(context, 'Thử lại', 'Retry'),
          );
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.subject,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(value: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${item.code} · ${_date(item.createdAt)}',
              style: TextStyle(color: context.appMuted),
            ),
            const SizedBox(height: 22),
            _DetailBlock(
              title: _t(context, 'Thông tin', 'Information'),
              child: Column(
                children: [
                  _DetailRow(
                    label: _t(context, 'Loại', 'Type'),
                    value: _type(context, item.type),
                  ),
                  _DetailRow(
                    label: _t(context, 'Đơn dịch vụ', 'Booking'),
                    value: '#${item.bookingCode}',
                  ),
                  if (item.technicianName?.isNotEmpty == true)
                    _DetailRow(
                      label: _t(context, 'Kỹ thuật viên', 'Technician'),
                      value: item.technicianName!,
                    ),
                ],
              ),
            ),
            _DetailBlock(
              title: _t(context, 'Nội dung của bạn', 'Your complaint'),
              child: Text(
                item.description,
                style: const TextStyle(height: 1.5),
              ),
            ),
            _DetailBlock(
              title: _t(
                context,
                'Phản hồi từ CoolCare',
                'Response from CoolCare',
              ),
              child: item.resolution?.trim().isNotEmpty == true
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.resolution!,
                          style: const TextStyle(height: 1.5),
                        ),
                        if (item.resolvedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _date(item.resolvedAt),
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(
                              context,
                              'Quản trị viên đang xem xét. Phản hồi sẽ hiển thị tại đây.',
                              'An administrator is reviewing your complaint. The response will appear here.',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class SubmitComplaintPage extends StatefulWidget {
  const SubmitComplaintPage({super.key});
  @override
  State<SubmitComplaintPage> createState() => _SubmitComplaintPageState();
}

class _SubmitComplaintPageState extends State<SubmitComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final _repository = ComplaintRepository();
  late Future<List<MyBooking>> _bookings;
  String? _bookingId;
  String? _type;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookings = MyBookingsRepository().getMyBookings(limit: 50);
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _bookingId == null ||
        _type == null) {
      setState(
        () => _error = _t(
          context,
          'Vui lòng điền đầy đủ thông tin bắt buộc.',
          'Please complete all required fields.',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.submit(
        bookingId: _bookingId!,
        type: _type!,
        subject: _subject.text,
        description: _description.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              'Đã gửi khiếu nại thành công.',
              'Complaint submitted successfully.',
            ),
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _t(
            context,
            'Không thể gửi khiếu nại. Vui lòng thử lại.',
            'Unable to submit complaint. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      title: Text(_t(context, 'Gửi khiếu nại', 'Submit complaint')),
    ),
    body: FutureBuilder<List<MyBooking>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageList(
            icon: Icons.cloud_off,
            title: _t(
              context,
              'Không thể tải danh sách đơn',
              'Unable to load bookings',
            ),
            subtitle: _loadErrorMessage(context, snapshot.error),
            action: () => setState(
              () => _bookings = MyBookingsRepository().getMyBookings(limit: 50),
            ),
            actionLabel: _t(context, 'Thử lại', 'Retry'),
          );
        }
        final bookings = snapshot.data ?? const [];
        if (bookings.isEmpty) {
          return _MessageList(
            icon: Icons.receipt_long_outlined,
            title: _t(
              context,
              'Bạn chưa có đơn dịch vụ',
              'You have no bookings',
            ),
            subtitle: _t(
              context,
              'Cần có đơn dịch vụ để gửi khiếu nại.',
              'A booking is required to submit a complaint.',
            ),
          );
        }
        return Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoolCareColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CoolCareColors.primary.withValues(alpha: .18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CoolCareColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(
                              context,
                              'CoolCare luôn sẵn sàng hỗ trợ',
                              'CoolCare is here to help',
                            ),
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _t(
                              context,
                              'Hãy cung cấp thông tin rõ ràng. Quản trị viên sẽ xem xét và phản hồi trong mục Khiếu nại của tôi.',
                              'Provide clear details. An administrator will review and respond in My Complaints.',
                            ),
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _FormSectionTitle(
                icon: Icons.receipt_long_outlined,
                title: _t(
                  context,
                  'Thông tin liên quan',
                  'Related information',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _bookingId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _t(context, 'Đơn dịch vụ *', 'Booking *'),
                  hintText: _t(
                    context,
                    'Chọn đơn cần hỗ trợ',
                    'Select a booking',
                  ),
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                items: bookings
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '#${b.code} · ${b.serviceNames ?? b.status}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _bookingId = value),
                validator: (value) => value == null
                    ? _t(
                        context,
                        'Vui lòng chọn đơn dịch vụ.',
                        'Please select a booking.',
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _t(
                    context,
                    'Loại khiếu nại *',
                    'Complaint type *',
                  ),
                  hintText: _t(
                    context,
                    'Chọn nhóm vấn đề',
                    'Select an issue category',
                  ),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: ['SERVICE', 'TECHNICIAN', 'PAYMENT', 'OTHER']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_typeLabel(context, value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value),
                validator: (value) => value == null
                    ? _t(
                        context,
                        'Vui lòng chọn loại.',
                        'Please select a type.',
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              _FormSectionTitle(
                icon: Icons.edit_note_rounded,
                title: _t(context, 'Nội dung khiếu nại', 'Complaint details'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subject,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: _t(context, 'Tiêu đề *', 'Subject *'),
                  hintText: _t(
                    context,
                    'Tóm tắt vấn đề bạn gặp phải',
                    'Briefly summarize the issue',
                  ),
                  prefixIcon: const Icon(Icons.short_text_rounded),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 5
                      ? _t(
                          context,
                          'Tiêu đề cần ít nhất 5 ký tự.',
                          'Subject must be at least 5 characters.',
                        )
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                minLines: 6,
                maxLines: 10,
                maxLength: 5000,
                decoration: InputDecoration(
                  labelText: _t(context, 'Nội dung chi tiết *', 'Details *'),
                  hintText: _t(
                    context,
                    'Mô tả sự việc, thời gian và mong muốn được hỗ trợ...',
                    'Describe what happened, when, and how we can help...',
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 112),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 20
                      ? _t(
                          context,
                          'Nội dung cần ít nhất 20 ký tự.',
                          'Details must be at least 20 characters.',
                        )
                      : null;
                },
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CoolCareColors.error.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoolCareColors.error.withValues(alpha: .25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: CoolCareColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: CoolCareColors.error,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_t(context, 'Gửi khiếu nại', 'Submit complaint')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: CoolCareColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: context.appText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

String _typeLabel(BuildContext context, String value) => _type(context, value);

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      'RESOLVED' => Colors.green,
      'REJECTED' => Colors.red,
      'IN_PROGRESS' => Colors.orange,
      'CLOSED' => Colors.blueGrey,
      _ => Colors.blue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status(context, value),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: context.appMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(28, 100, 28, 20),
    children: [
      Icon(icon, size: 54, color: context.appMuted),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, height: 1.4),
          ),
        ),
      if (action != null)
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Center(
            child: OutlinedButton(
              onPressed: action,
              child: Text(actionLabel ?? _t(context, 'Tiếp tục', 'Continue')),
            ),
          ),
        ),
    ],
  );
}
