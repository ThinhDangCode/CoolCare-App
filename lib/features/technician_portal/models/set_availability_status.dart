class SetAvailabilityStatus {
  const SetAvailabilityStatus({
    required this.status,
    required this.canReceiveJobs,
    this.updatedAt,
  });

  factory SetAvailabilityStatus.fromJson(Map<String, dynamic> json) {
    final status = json['availability_status']?.toString() ?? 'OFFLINE';
    return SetAvailabilityStatus(
      status: const {'ONLINE', 'OFFLINE'}.contains(status) ? status : 'OFFLINE',
      canReceiveJobs: json['can_receive_jobs'] == true,
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  final String status;
  final bool canReceiveJobs;
  final DateTime? updatedAt;

  bool get isOnline => status == 'ONLINE';
}
