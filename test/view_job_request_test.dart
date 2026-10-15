import 'package:coolcare_mobile/features/technician_portal/models/view_job_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ViewJobRequest parses the backend View Job Requests response', () {
    final request = ViewJobRequest.fromJson({
      'id': 'request-id',
      'status': 'SELECTED',
      'canRespond': true,
      'canComplete': false,
      'requestedAt': '2026-10-15T01:00:00.000Z',
      'matchScore': 95.5,
      'matchReason': 'Phù hợp khu vực',
      'booking': {
        'id': 'booking-id',
        'code': 'BK-001',
        'status': 'TECHNICIAN_SELECTED',
        'scheduledAt': '2026-10-16T07:00:00.000Z',
        'address': {
          'addressLine': '1 Nguyễn Văn Cừ',
          'ward': 'Phường Ninh Kiều',
          'city': 'Cần Thơ',
        },
        'recipient': {'name': 'Khách hàng', 'phone': '0900000000'},
        'pricing': {'totalAmount': 350000},
        'units': [
          {
            'unitNumber': 1,
            'brandName': 'Daikin',
            'modelName': 'FTKB',
            'services': [
              {'id': 'service-id', 'name': 'AC Cleaning', 'unitPrice': 350000},
            ],
          },
        ],
      },
      'customer': {'id': 'customer-id', 'name': 'Khách hàng'},
    });

    expect(request.status, 'SELECTED');
    expect(request.canRespond, isTrue);
    expect(request.canComplete, isFalse);
    expect(request.booking.primaryServiceName, 'AC Cleaning');
    expect(
      request.booking.address,
      '1 Nguyễn Văn Cừ, Phường Ninh Kiều, Cần Thơ',
    );
    expect(request.booking.totalAmount, 350000);
    expect(request.matchScore, 95.5);
  });

  test(
    'ViewJobRequest rejects a response without booking or customer objects',
    () {
      expect(
        () => ViewJobRequest.fromJson({'id': 'request-id'}),
        throwsFormatException,
      );
    },
  );
}
