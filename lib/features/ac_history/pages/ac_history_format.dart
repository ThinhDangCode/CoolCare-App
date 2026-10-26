import 'package:flutter/material.dart';

String acMoney(num value) {
  final n = value.round();
  final text = n.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${n < 0 ? '-' : ''}$text ₫';
}

String acDate(DateTime? date) {
  if (date == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

String acDateTime(DateTime? date) {
  if (date == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${acDate(date)} · ${two(date.hour)}:${two(date.minute)}';
}

String acStatusLabel(String status, bool vi) {
  const labels = {
    'PENDING': ('Chờ xử lý', 'Pending'),
    'TECHNICIAN_SELECTED': ('Đã chọn kỹ thuật viên', 'Technician selected'),
    'ACCEPTED': ('Đã nhận đơn', 'Accepted'),
    'IN_PROGRESS': ('Đang thực hiện', 'In progress'),
    'WAITING_QUOTATION': ('Chờ báo giá', 'Waiting for quote'),
    'QUOTATION_SENT': ('Đã gửi báo giá', 'Quote sent'),
    'QUOTATION_ACCEPTED': ('Đã duyệt báo giá', 'Quote approved'),
    'QUOTATION_REJECTED': ('Từ chối báo giá', 'Quote rejected'),
    'WAITING_CONFIRMATION': ('Chờ xác nhận', 'Awaiting confirmation'),
    'COMPLETED': ('Hoàn thành', 'Completed'),
    'CANCELLED': ('Đã hủy', 'Cancelled'),
  };
  final label = labels[status.toUpperCase()];
  if (label == null) return vi ? 'Không xác định' : 'Unknown';
  return vi ? label.$1 : label.$2;
}

Color acStatusColor(String status, ColorScheme scheme) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return const Color(0xFF13856A);
    case 'CANCELLED':
    case 'QUOTATION_REJECTED':
      return scheme.error;
    default:
      return const Color(0xFFB07716);
  }
}
