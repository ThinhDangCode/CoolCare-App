import 'package:flutter/widgets.dart';

const _titles = <String, String>{
  'Đã tạo lịch hẹn': 'Booking created',
  'Kỹ thuật viên đã nhận công việc': 'Technician accepted the job',
  'Kỹ thuật viên đã từ chối công việc': 'Technician declined the job',
  'Kỹ thuật viên đã hủy công việc': 'Technician cancelled the job',
  'Hóa đơn dịch vụ và xác nhận hoàn thành': 'Service completed: confirmation needed',
  'Khách hàng đã xác nhận hoàn thành': 'Customer confirmed completion',
  'Phản hồi báo giá': 'Quotation response',
  'Báo giá mới': 'New quotation',
  'Voucher bồi thường khiếu nại': 'Complaint compensation voucher',
  'Thông báo đối soát tuần': 'Weekly settlement update',
  'Hóa đơn đã được gửi qua email': 'Invoice sent by email',
  'Bạn nhận được đánh giá mới': 'You received a new review',
  'Đăng ký kỹ thuật viên đã được duyệt': 'Technician application approved',
  'Đăng ký kỹ thuật viên cần cập nhật': 'Technician application needs changes',
};

const _messages = <String, String>{
  'Bạn có báo giá cần phản hồi.': 'You have a quotation to review.',
  'Khách hàng đã chấp nhận báo giá.': 'The customer accepted the quotation.',
  'Khách hàng đã từ chối báo giá.': 'The customer declined the quotation.',
  'Hồ sơ của bạn đã được duyệt thành công. Bạn có thể chuyển sang chế độ kỹ thuật viên để nhận công việc.':
      'Your application was approved. You can switch to Technician Mode to receive jobs.',
};

String localizedNotificationTitle(BuildContext context, String title) {
  if (Localizations.localeOf(context).languageCode != 'en') return title;
  return _titles[title] ?? title;
}

String localizedNotificationMessage(BuildContext context, String message) {
  if (Localizations.localeOf(context).languageCode != 'en') return message;
  final exact = _messages[message];
  if (exact != null) return exact;

  final accepted = RegExp(r'^Yêu cầu cho booking (.+) đã được kỹ thuật viên chấp nhận\.$').firstMatch(message);
  if (accepted != null) return 'The technician accepted booking ${accepted[1]}.';
  final declined = RegExp(r'^Yêu cầu cho booking (.+) đã bị từ chối\. Bạn có thể chọn kỹ thuật viên khác\.$').firstMatch(message);
  if (declined != null) return 'Booking ${declined[1]} was declined. You can choose another technician.';
  final cancelled = RegExp(r'^Booking (.+): kỹ thuật viên đã hủy\. Bạn có thể chọn kỹ thuật viên khác\.$').firstMatch(message);
  if (cancelled != null) return 'The technician cancelled booking ${cancelled[1]}. You can choose another technician.';
  final completed = RegExp(r'^Kỹ thuật viên đã hoàn thành booking (.+)\. Tổng tiền dịch vụ: (.+)đ\. Vui lòng kiểm tra hóa đơn và xác nhận hoàn thành\.$').firstMatch(message);
  if (completed != null) return 'The technician completed booking ${completed[1]}. Service total: ${completed[2]} VND. Review the invoice and confirm completion.';
  final confirmed = RegExp(r'^Booking (.+) đã được khách hàng xác nhận hoàn thành\.$').firstMatch(message);
  if (confirmed != null) return 'The customer confirmed completion of booking ${confirmed[1]}.';
  final invoice = RegExp(r'^Hóa đơn (.+) đã được gửi tới email của bạn\.$').firstMatch(message);
  if (invoice != null) return 'Invoice ${invoice[1]} was sent to your email.';
  final voucher = RegExp(r'^Bạn đã nhận voucher (.+) trị giá (.+)đ cho khiếu nại (.+)\.$').firstMatch(message);
  if (voucher != null) return 'You received voucher ${voucher[1]} worth ${voucher[2]} VND for complaint ${voucher[3]}.';
  final review = RegExp(r'^Bạn nhận được đánh giá (\d+)/5 sao cho booking ([^.:]+)([.:].*)?$').firstMatch(message);
  if (review != null) return 'You received a ${review[1]}/5 star review for booking ${review[2]}${review[3] ?? '.'}';
  return message;
}
