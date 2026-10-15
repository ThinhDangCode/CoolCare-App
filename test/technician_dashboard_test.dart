import 'package:coolcare_mobile/features/technician_portal/models/technician_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard parses the exact request count and next booking id', () {
    final dashboard = TechnicianDashboard.fromJson({
      'technician': {
        'full_name': 'Nguyễn Minh An',
        'availability_status': 'ONLINE',
      },
      'stats': {
        'jobs_today': 1,
        'earnings_today': 200000,
        'pending_requests': 2,
      },
      'next_job': {
        'id': 'booking-id',
        'service_name': 'AC Cleaning',
        'assignment_status': 'SELECTED',
      },
    });

    expect(dashboard.pendingRequests, 2);
    expect(dashboard.nextJob?.id, 'booking-id');
    expect(dashboard.nextJob?.status, 'SELECTED');
  });
}
