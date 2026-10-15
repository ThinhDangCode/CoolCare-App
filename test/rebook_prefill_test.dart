import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/features/booking/controllers/booking_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Re-book pre-fills customer details, AC units and services but requires a new schedule',
    () async {
      final controller = BookingController(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
      );

      await controller.prefillFromBooking({
        'description': 'Máy lạnh kêu lớn',
        'scheduledAt': '2026-10-16T07:00:00.000Z',
        'recipient': {'name': 'Nguyễn Văn An', 'phone': '0900000000'},
        'units': [
          {
            'description': 'Kiểm tra dàn nóng',
            'ac_brand_id': null,
            'ac_model_id': null,
            'services': [
              {'id': 'service-id', 'name': 'Vệ sinh máy lạnh'},
            ],
          },
        ],
      });

      expect(controller.recipientName, 'Nguyễn Văn An');
      expect(controller.recipientPhone, '0900000000');
      expect(controller.description, 'Máy lạnh kêu lớn');
      expect(controller.units, hasLength(1));
      expect(controller.units.first.description, 'Kiểm tra dàn nóng');
      expect(controller.units.first.serviceIds, ['service-id']);
      expect(controller.scheduledAt, isNull);

      controller.dispose();
    },
  );
}
