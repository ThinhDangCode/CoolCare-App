class CancelAcceptedJobResult {
  const CancelAcceptedJobResult({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.bookingStatus,
    this.penaltyPoints,
  });

  factory CancelAcceptedJobResult.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    if (booking is! Map<String, dynamic>) {
      throw const FormatException('Invalid cancel accepted job response.');
    }
    final penalty = json['penalty'];
    return CancelAcceptedJobResult(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      bookingStatus: booking['status']?.toString() ?? '',
      penaltyPoints: penalty is Map<String, dynamic>
          ? (penalty['points'] as num?)?.toInt()
          : null,
    );
  }

  final String id;
  final String bookingId;
  final String status;
  final String bookingStatus;
  final int? penaltyPoints;
}
