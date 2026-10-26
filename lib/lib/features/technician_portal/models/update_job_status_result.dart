class UpdateJobStatusResult {
  const UpdateJobStatusResult({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.bookingStatus,
    this.completedAt,
  });

  factory UpdateJobStatusResult.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    if (booking is! Map<String, dynamic>) {
      throw const FormatException('Invalid update job status response.');
    }
    return UpdateJobStatusResult(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      bookingStatus: booking['status']?.toString() ?? '',
      completedAt: DateTime.tryParse(booking['completedAt']?.toString() ?? ''),
    );
  }

  final String id;
  final String bookingId;
  final String status;
  final String bookingStatus;
  final DateTime? completedAt;
}
