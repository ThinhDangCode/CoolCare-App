import 'package:coolcare_mobile/features/technician_portal/models/update_job_status_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UpdateJobStatusResult parses a completed response', () {
    final result = UpdateJobStatusResult.fromJson({
      'id': 'request-id',
      'bookingId': 'booking-id',
      'status': 'COMPLETED',
      'booking': {
        'status': 'COMPLETED',
        'completedAt': '2026-10-15T09:00:00.000Z',
      },
    });

    expect(result.status, 'COMPLETED');
    expect(result.bookingStatus, 'COMPLETED');
    expect(result.completedAt, isNotNull);
  });
}
