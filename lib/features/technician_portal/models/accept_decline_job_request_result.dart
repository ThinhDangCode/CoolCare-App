class AcceptDeclineJobRequestResult {
  const AcceptDeclineJobRequestResult({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.bookingStatus,
    this.respondedAt,
    this.declineReason,
  });

  factory AcceptDeclineJobRequestResult.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    if (booking is! Map<String, dynamic>) {
      throw const FormatException('Invalid job response booking.');
    }
    final status = json['status']?.toString() ?? '';
    if (!const {'ACCEPTED', 'DECLINED'}.contains(status)) {
      throw const FormatException('Invalid job response status.');
    }
    return AcceptDeclineJobRequestResult(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      status: status,
      respondedAt: DateTime.tryParse(json['respondedAt']?.toString() ?? ''),
      declineReason: json['declineReason']?.toString(),
      bookingStatus: booking['status']?.toString() ?? '',
    );
  }

  final String id;
  final String bookingId;
  final String status;
  final DateTime? respondedAt;
  final String? declineReason;
  final String bookingStatus;
}
