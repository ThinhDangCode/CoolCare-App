import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/features/booking/pages/booking_detail_page.dart';
import 'package:coolcare_mobile/features/booking/repositories/booking_detail_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customer can confirm completion from booking detail', (
    tester,
  ) async {
    final repository = _FakeBookingDetailRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: BookingDetailPage(
          bookingId: 'booking-id',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.text('Confirm completion');
    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Confirm completion').last,
    );
    await tester.pumpAndSettle();

    expect(repository.confirmedBookingId, 'booking-id');
  });
}

class _FakeBookingDetailRepository extends BookingDetailRepository {
  _FakeBookingDetailRepository()
    : super(apiClient: ApiClient(baseUrl: 'http://localhost'));

  String? confirmedBookingId;

  @override
  Future<Map<String, dynamic>> getDetail(String id) async => {
    'id': id,
    'bookingCode': 'BK-001',
    'status': 'ACCEPTED',
    'scheduledAt': '2026-10-16T07:00:00.000Z',
    'address': {
      'addressLine': '1 Test',
      'ward': 'Ninh Kiều',
      'city': 'Cần Thơ',
    },
    'recipient': {'name': 'Customer', 'phone': '0900000000'},
    'pricing': {'totalAmount': 350000},
    'units': <dynamic>[],
    'timeline': <dynamic>[],
    'canCancel': false,
    'canConfirmCompletion': true,
  };

  @override
  Future<List<Map<String, dynamic>>> getTimeline(String id) async => [];

  @override
  Future<Map<String, dynamic>> confirmCompletion(String id) async {
    confirmedBookingId = id;
    return {'id': id, 'status': 'COMPLETED'};
  }
}
