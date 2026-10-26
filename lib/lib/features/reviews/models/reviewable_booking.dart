class ReviewableBooking {
  const ReviewableBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.services,
    required this.technician,
    required this.reviewed,
    this.reviewId,
    this.reviewRating,
    this.reviewComment,
    required this.scheduledAt,
  });

  final String id;
  final String code;
  final String status;
  final String services;
  final String technician;
  final bool reviewed;
  final String? reviewId;
  final int? reviewRating;
  final String? reviewComment;
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
      reviewId: json['review_id']?.toString(),
      reviewRating: (json['review_rating'] as num?)?.toInt(),
      reviewComment: json['review_comment']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
    );
  }
}
