import 'package:coolcare_mobile/features/technician_portal/models/cancel_accepted_job_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CancelAcceptedJobResult parses cancellation and penalty', () {
    final result = CancelAcceptedJobResult.fromJson({
      'id': 'request-id',
      'bookingId': 'booking-id',
      'status': 'CANCELLED',
      'booking': {'status': 'CANCELLED'},
      'penalty': {'points': 10},
    });

    expect(result.status, 'CANCELLED');
    expect(result.bookingStatus, 'CANCELLED');
    expect(result.penaltyPoints, 10);
  });
}
