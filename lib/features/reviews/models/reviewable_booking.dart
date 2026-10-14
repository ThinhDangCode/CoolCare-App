class ReviewableBooking {
  const ReviewableBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.services,
    required this.technician,
    required this.reviewed,
    required this.scheduledAt,
  });

  final String id;
  final String code;
  final String status;
  final String services;
  final String technician;
  final bool reviewed;
  final DateTime? scheduledAt;

  bool get canReview =>
      status == 'COMPLETED' && !reviewed && technician != 'Unassigned';

  factory ReviewableBooking.fromJson(Map<String, dynamic> json) {
    return ReviewableBooking(
      id: json['id']?.toString() ?? '',
      code: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      services: json['service_names']?.toString() ?? 'AC service',
      technician: json['technician_name']?.toString() ?? 'Unassigned',
      reviewed: json['reviewed'] == true,
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
    );
  }
}
