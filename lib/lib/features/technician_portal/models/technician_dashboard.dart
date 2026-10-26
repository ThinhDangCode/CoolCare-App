class TechnicianDashboard {
  const TechnicianDashboard({
    required this.name,
    required this.qualification,
    required this.availability,
    required this.rating,
    required this.jobsToday,
    required this.earningsToday,
    required this.pendingRequests,
    this.avatarUrl,
    this.nextJob,
  });

  factory TechnicianDashboard.fromJson(Map<String, dynamic> json) {
    final technician = json['technician'] as Map<String, dynamic>? ?? const {};
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final job = json['next_job'];
    return TechnicianDashboard(
      name: technician['full_name']?.toString() ?? '',
      avatarUrl: technician['avatar_url']?.toString(),
      qualification:
          technician['qualification_level']?.toString() ?? 'BEGINNER',
      availability: technician['availability_status']?.toString() ?? 'OFFLINE',
      rating:
          double.tryParse(technician['rating_average']?.toString() ?? '') ?? 0,
      jobsToday: int.tryParse(stats['jobs_today']?.toString() ?? '') ?? 0,
      earningsToday:
          double.tryParse(stats['earnings_today']?.toString() ?? '') ?? 0,
      pendingRequests:
          int.tryParse(stats['pending_requests']?.toString() ?? '') ?? 0,
      nextJob: job is Map<String, dynamic>
          ? TechnicianNextJob.fromJson(job)
          : null,
    );
  }

  final String name;
  final String? avatarUrl;
  final String qualification;
  final String availability;
  final double rating;
  final int jobsToday;
  final double earningsToday;
  final int pendingRequests;
  final TechnicianNextJob? nextJob;

  TechnicianDashboard withAvailability(String value) => TechnicianDashboard(
    name: name,
    avatarUrl: avatarUrl,
    qualification: qualification,
    availability: value,
    rating: rating,
    jobsToday: jobsToday,
    earningsToday: earningsToday,
    pendingRequests: pendingRequests,
    nextJob: nextJob,
  );
}

class TechnicianNextJob {
  const TechnicianNextJob({
    required this.id,
    required this.serviceName,
    required this.address,
    required this.status,
    this.scheduledAt,
  });

  factory TechnicianNextJob.fromJson(Map<String, dynamic> json) =>
      TechnicianNextJob(
        id: json['id']?.toString() ?? '',
        serviceName: json['service_name']?.toString() ?? 'CoolCare Service',
        address: [json['service_address'], json['ward'], json['city']]
            .where((value) => value?.toString().trim().isNotEmpty == true)
            .join(', '),
        status: json['assignment_status']?.toString() ?? 'ACCEPTED',
        scheduledAt: DateTime.tryParse(
          json['scheduled_at']?.toString() ?? '',
        )?.toLocal(),
      );

  final String id;
  final String serviceName;
  final String address;
  final String status;
  final DateTime? scheduledAt;
}
