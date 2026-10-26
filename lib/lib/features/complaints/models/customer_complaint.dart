class CustomerComplaint {
  const CustomerComplaint({
    required this.id,
    required this.code,
    required this.bookingId,
    required this.bookingCode,
    required this.type,
    required this.status,
    required this.subject,
    required this.description,
    required this.createdAt,
    this.resolution,
    this.resolvedAt,
    this.technicianName,
  });

  final String id;
  final String code;
  final String bookingId;
  final String bookingCode;
  final String type;
  final String status;
  final String subject;
  final String description;
  final DateTime? createdAt;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? technicianName;

  factory CustomerComplaint.fromJson(Map<String, dynamic> json) =>
      CustomerComplaint(
        id: json['id']?.toString() ?? '',
        code: json['complaint_code']?.toString() ?? '',
        bookingId: json['booking_id']?.toString() ?? '',
        bookingCode: json['booking_code']?.toString() ?? '',
        type: json['type']?.toString() ?? 'OTHER',
        status: json['status']?.toString() ?? 'OPEN',
        subject: json['subject']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        resolution: json['resolution']?.toString(),
        resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
        technicianName: json['technician_name']?.toString(),
      );
}
