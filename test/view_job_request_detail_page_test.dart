import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/features/technician_portal/models/accept_decline_job_request_result.dart';
import 'package:coolcare_mobile/features/technician_portal/models/view_job_request.dart';
import 'package:coolcare_mobile/features/technician_portal/models/update_job_status_result.dart';
import 'package:coolcare_mobile/features/technician_portal/models/cancel_accepted_job_result.dart';
import 'package:coolcare_mobile/features/technician_portal/pages/view_job_request_detail_page.dart';
import 'package:coolcare_mobile/features/technician_portal/repositories/technician_portal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Job Details uses booking data and does not render a map placeholder',
    (tester) async {
      final request = ViewJobRequest.fromJson({
        'id': 'request-id',
        'status': 'SELECTED',
        'canRespond': true,
        'booking': {
          'id': 'booking-id',
          'code': 'BK-001',
          'status': 'TECHNICIAN_SELECTED',
          'description': 'Please check the compressor.',
          'scheduledAt': '2026-10-16T07:00:00.000Z',
          'address': {
            'addressLine': '1 Nguyễn Văn Cừ',
            'ward': 'Phường Ninh Kiều',
            'city': 'Cần Thơ',
          },
          'recipient': {'name': 'Nguyễn Văn An', 'phone': '0900000000'},
          'pricing': {'totalAmount': 350000},
          'units': [
            {
              'unitNumber': 1,
              'brandName': 'Daikin',
              'modelName': 'FTKB',
              'services': [
                {
                  'id': 'service-id',
                  'name': 'AC Deep Cleaning',
                  'unitPrice': 350000,
                },
              ],
            },
          ],
        },
        'customer': {'id': 'customer-id', 'name': 'Nguyễn Văn An'},
      });

      await tester.pumpWidget(
        MaterialApp(home: ViewJobRequestDetailPage(request: request)),
      );

      expect(find.text('Job Details'), findsOneWidget);
      expect(find.text('AC Deep Cleaning (1 unit)'), findsOneWidget);
      expect(find.text('Daikin FTKB'), findsOneWidget);
      expect(find.text('Please check the compressor.'), findsOneWidget);
      expect(find.text('Accept Job'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.textContaining('Map'), findsNothing);
    },
  );

  testWidgets('Decline confirmation sends the optional reason to the API', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ViewJobRequestDetailPage(
          request: _request(),
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Busy at this time');
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(repository.requestId, 'request-id');
    expect(repository.accept, isFalse);
    expect(repository.reason, 'Busy at this time');
  });

  testWidgets('Accept confirmation sends the request to the API', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ViewJobRequestDetailPage(
          request: _request(),
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.text('Accept Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept Job').last);
    await tester.pumpAndSettle();

    expect(repository.requestId, 'request-id');
    expect(repository.accept, isTrue);
    expect(repository.reason, isNull);
  });

  testWidgets('Complete confirmation updates an ongoing job', (tester) async {
    final repository = _FakeTechnicianPortalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ViewJobRequestDetailPage(
          request: _request(canRespond: false, canComplete: true),
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.text('Complete Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Complete Job').last);
    await tester.pumpAndSettle();

    expect(repository.completedRequestId, 'request-id');
  });

  testWidgets('Cancel accepted job requires a reason and sends it to the API', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ViewJobRequestDetailPage(
          request: _request(
            canRespond: false,
            canComplete: true,
            canCancelAcceptedJob: true,
          ),
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Cancel Job'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Family emergency');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Job'));
    await tester.pumpAndSettle();

    expect(repository.cancelledRequestId, 'request-id');
    expect(repository.cancellationReason, 'Family emergency');
  });
}

ViewJobRequest _request({
  bool canRespond = true,
  bool canComplete = false,
  bool canCancelAcceptedJob = false,
}) => ViewJobRequest.fromJson({
  'id': 'request-id',
  'status': canComplete ? 'ACCEPTED' : 'SELECTED',
  'canRespond': canRespond,
  'canComplete': canComplete,
  'canCancelAcceptedJob': canCancelAcceptedJob,
  'booking': {
    'id': 'booking-id',
    'code': 'BK-001',
    'status': canComplete ? 'ACCEPTED' : 'TECHNICIAN_SELECTED',
    'scheduledAt': '2026-10-16T07:00:00.000Z',
    'address': {
      'addressLine': '1 Nguyễn Văn Cừ',
      'ward': 'Phường Ninh Kiều',
      'city': 'Cần Thơ',
    },
    'recipient': {'name': 'Nguyễn Văn An', 'phone': '0900000000'},
    'pricing': {'totalAmount': 350000},
    'units': <Map<String, dynamic>>[],
  },
  'customer': {'id': 'customer-id', 'name': 'Nguyễn Văn An'},
});

class _FakeTechnicianPortalRepository extends TechnicianPortalRepository {
  _FakeTechnicianPortalRepository()
    : super(apiClient: ApiClient(baseUrl: 'http://localhost'));

  String? requestId;
  bool? accept;
  String? reason;
  String? completedRequestId;
  String? cancelledRequestId;
  String? cancellationReason;

  @override
  Future<AcceptDeclineJobRequestResult> respondToJobRequest(
    String requestId, {
    required bool accept,
    String? reason,
  }) async {
    this.requestId = requestId;
    this.accept = accept;
    this.reason = reason;
    return AcceptDeclineJobRequestResult(
      id: 'request-id',
      bookingId: 'booking-id',
      status: accept ? 'ACCEPTED' : 'DECLINED',
      bookingStatus: accept ? 'ACCEPTED' : 'CANCELLED',
    );
  }

  @override
  Future<UpdateJobStatusResult> completeJob(String requestId) async {
    completedRequestId = requestId;
    return const UpdateJobStatusResult(
      id: 'request-id',
      bookingId: 'booking-id',
      status: 'ACCEPTED',
      bookingStatus: 'WAITING_CONFIRMATION',
    );
  }

  @override
  Future<CancelAcceptedJobResult> cancelAcceptedJob(
    String requestId, {
    required String reason,
  }) async {
    cancelledRequestId = requestId;
    cancellationReason = reason;
    return const CancelAcceptedJobResult(
      id: 'request-id',
      bookingId: 'booking-id',
      status: 'CANCELLED',
      bookingStatus: 'CANCELLED',
      penaltyPoints: 10,
    );
  }
}
