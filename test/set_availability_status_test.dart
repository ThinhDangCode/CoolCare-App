import 'package:coolcare_mobile/features/technician_portal/models/set_availability_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SetAvailabilityStatus parses ONLINE state from the API', () {
    final status = SetAvailabilityStatus.fromJson({
      'availability_status': 'ONLINE',
      'can_receive_jobs': true,
      'updated_at': '2026-10-14T08:00:00.000Z',
    });

    expect(status.status, 'ONLINE');
    expect(status.isOnline, isTrue);
    expect(status.canReceiveJobs, isTrue);
    expect(status.updatedAt, isNotNull);
  });

  test('SetAvailabilityStatus treats non-toggle states as OFFLINE', () {
    final status = SetAvailabilityStatus.fromJson({
      'availability_status': 'BUSY',
      'can_receive_jobs': false,
    });

    expect(status.status, 'OFFLINE');
    expect(status.isOnline, isFalse);
    expect(status.canReceiveJobs, isFalse);
  });

  test('SetAvailabilityStatus safely falls back to OFFLINE', () {
    final status = SetAvailabilityStatus.fromJson({
      'availability_status': 'UNKNOWN',
    });

    expect(status.status, 'OFFLINE');
    expect(status.isOnline, isFalse);
    expect(status.canReceiveJobs, isFalse);
  });
}
