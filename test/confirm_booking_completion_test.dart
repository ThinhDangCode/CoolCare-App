import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/features/booking/pages/booking_detail_page.dart';
import 'package:coolcare_mobile/features/booking/repositories/booking_detail_repository.dart';
import 'package:coolcare_mobile/features/payments/repositories/payment_repository.dart';
import 'package:coolcare_mobile/features/payments/pages/payment_page.dart';
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
          paymentRepository: _FakePaymentRepository(),
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
    // PaymentPage polls periodically, so it intentionally never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.confirmedBookingId, 'booking-id');
  });

  testWidgets('Confirm Booking UTCID03 backs out without repository call', (
    tester,
  ) async {
    final repository = _FakeBookingDetailRepository();
    await _openConfirmation(tester, repository);
    await tester.tap(find.widgetWithText(TextButton, 'Back'));
    await tester.pumpAndSettle();

    expect(repository.confirmCalls, 0);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('Confirm Booking UTCID04 shows repository failure', (
    tester,
  ) async {
    final repository = _FakeBookingDetailRepository()
      ..confirmationError = Exception('Denied');
    await _openConfirmation(tester, repository);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Confirm completion').last,
    );
    await tester.pumpAndSettle();

    expect(repository.confirmCalls, 1);
    expect(find.textContaining('Could not confirm completion'), findsOneWidget);
    expect(find.byType(BookingDetailPage), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm completion').first,
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Confirm Booking UTCID05 shows success and opens payment', (
    tester,
  ) async {
    final repository = _FakeBookingDetailRepository();
    await _openConfirmation(tester, repository);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Confirm completion').last,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.confirmedBookingId, 'booking-id');
    expect(find.text('Job completion confirmed'), findsOneWidget);
    expect(find.byType(PaymentPage), findsOneWidget);
  });
}

Future<void> _openConfirmation(
  WidgetTester tester,
  _FakeBookingDetailRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BookingDetailPage(
        bookingId: 'booking-id',
        repository: repository,
        paymentRepository: _FakePaymentRepository(),
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
  await tester.tap(button);
  await tester.pumpAndSettle();
}

class _FakePaymentRepository extends PaymentRepository {
  _FakePaymentRepository()
    : super(apiClient: ApiClient(baseUrl: 'http://localhost'));

  @override
  Future<Map<String, dynamic>> summary(String bookingId) async => {};
}

class _FakeBookingDetailRepository extends BookingDetailRepository {
  _FakeBookingDetailRepository()
    : super(apiClient: ApiClient(baseUrl: 'http://localhost'));

  String? confirmedBookingId;
  Object? confirmationError;
  int confirmCalls = 0;

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
    confirmCalls++;
    if (confirmationError case final error?) throw error;
    confirmedBookingId = id;
    return {'id': id, 'status': 'COMPLETED'};
  }
}
