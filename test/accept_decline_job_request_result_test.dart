import 'package:coolcare_mobile/features/technician_portal/models/accept_decline_job_request_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AcceptDeclineJobRequestResult parses the backend response', () {
    final result = AcceptDeclineJobRequestResult.fromJson({
      'id': 'request-id',
      'bookingId': 'booking-id',
      'status': 'ACCEPTED',
      'respondedAt': '2026-10-15T08:00:00.000Z',
      'declineReason': null,
      'booking': {'status': 'ACCEPTED'},
    });

    expect(result.status, 'ACCEPTED');
    expect(result.bookingStatus, 'ACCEPTED');
    expect(result.respondedAt, isNotNull);
  });

  test('AcceptDeclineJobRequestResult rejects unsupported states', () {
    expect(
      () => AcceptDeclineJobRequestResult.fromJson({
        'status': 'SELECTED',
        'booking': {'status': 'TECHNICIAN_SELECTED'},
      }),
      throwsFormatException,
    );
  });
}
