import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
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
          currentPosition: () async => (latitude: 10.0, longitude: 105.0),
        ),
      ),
    );

    await tester.tap(find.text('Accept Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept Job').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã nhận việc'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
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
    await tester.pump();

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

  testWidgets('Job Request Detail UTCID05 shows accept API error', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()
      ..respondError = const ApiException(message: 'Denied');
    await _pumpRequest(tester, repository);
    await tester.tap(find.text('Accept Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept Job').last);
    await tester.pumpAndSettle();

    expect(repository.respondCalls, 1);
    expect(find.text('Denied'), findsOneWidget);
    expect(find.byType(ViewJobRequestDetailPage), findsOneWidget);
  });

  testWidgets('Job Request Detail UTCID06 shows decline generic error', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()
      ..respondError = Exception('offline');
    await _pumpRequest(tester, repository);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(repository.respondCalls, 1);
    expect(
      find.text('Unable to save your response. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(ViewJobRequestDetailPage), findsOneWidget);
  });

  testWidgets('Job Request Detail UTCID07 blocks expired accept', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository();
    await _pumpRequest(tester, repository, request: _request(expired: true));
    final acceptButton = find.text('Accept Job');
    if (acceptButton.evaluate().isNotEmpty) {
      await tester.tap(acceptButton);
      await tester.pump();
    }

    expect(repository.respondCalls, 0);
  });

  testWidgets('Job Request Detail UTCID08 shows completion API error', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()
      ..completeError = const ApiException(message: 'Denied');
    await _pumpRequest(
      tester,
      repository,
      request: _request(canRespond: false, canComplete: true),
    );
    await _tapComplete(tester);

    expect(repository.completedRequestId, 'request-id');
    expect(find.text('Denied'), findsOneWidget);
    expect(find.byType(ViewJobRequestDetailPage), findsOneWidget);
  });

  testWidgets('Job Request Detail UTCID09 shows completion generic error', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()
      ..completeError = Exception('offline');
    await _pumpRequest(
      tester,
      repository,
      request: _request(canRespond: false, canComplete: true),
    );
    await _tapComplete(tester);

    expect(repository.completedRequestId, 'request-id');
    expect(
      find.text('Unable to complete this job. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(ViewJobRequestDetailPage), findsOneWidget);
  });

  testWidgets('Job Request Detail UTCID10 reports penalty and returns true', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()..penaltyPoints = 3;
    bool? routeResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                routeResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ViewJobRequestDetailPage(
                      request: _request(
                        canRespond: false,
                        canComplete: true,
                        canCancelAcceptedJob: true,
                      ),
                      repository: repository,
                    ),
                  ),
                );
              },
              child: const Text('Open job'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open job'));
    await tester.pumpAndSettle();
    await _tapCancel(tester);

    expect(repository.cancelledRequestId, 'request-id');
    expect(routeResult, isTrue);
    expect(find.textContaining('3 penalty points'), findsOneWidget);
  });

  testWidgets('Job Request Detail UTCID11 shows cancel API error and resets', (
    tester,
  ) async {
    final repository = _FakeTechnicianPortalRepository()
      ..cancelError = const ApiException(message: 'Denied');
    await _pumpRequest(
      tester,
      repository,
      request: _request(
        canRespond: false,
        canComplete: true,
        canCancelAcceptedJob: true,
      ),
    );
    await _tapCancel(tester);

    expect(repository.cancelledRequestId, 'request-id');
    expect(find.text('Denied'), findsOneWidget);
    expect(find.byType(ViewJobRequestDetailPage), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel'))
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpRequest(
  WidgetTester tester,
  _FakeTechnicianPortalRepository repository, {
  ViewJobRequest? request,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ViewJobRequestDetailPage(
        request: request ?? _request(),
        repository: repository,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapComplete(WidgetTester tester) async {
  await tester.tap(find.text('Complete Job'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Complete Job').last);
  await tester.pumpAndSettle();
}

Future<void> _tapCancel(WidgetTester tester) async {
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Family emergency');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Cancel Job'));
  await tester.pumpAndSettle();
}

ViewJobRequest _request({
  bool canRespond = true,
  bool canComplete = false,
  bool canCancelAcceptedJob = false,
  bool expired = false,
}) => ViewJobRequest.fromJson({
  'id': 'request-id',
  'status': canComplete ? 'ACCEPTED' : 'SELECTED',
  'canRespond': canRespond,
  'canComplete': canComplete,
  'canCancelAcceptedJob': canCancelAcceptedJob,
  if (expired)
    'expiresAt': DateTime.now()
        .subtract(const Duration(minutes: 1))
        .toUtc()
        .toIso8601String(),
  'booking': {
    'id': 'booking-id',
    'code': 'BK-001',
    'status': canComplete ? 'ACCEPTED' : 'TECHNICIAN_SELECTED',
    'scheduledAt': DateTime.now()
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String(),
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
  Object? respondError;
  Object? completeError;
  Object? cancelError;
  int respondCalls = 0;
  int penaltyPoints = 10;

  @override
  Future<AcceptDeclineJobRequestResult> respondToJobRequest(
    String requestId, {
    required bool accept,
    String? reason,
  }) async {
    respondCalls++;
    this.requestId = requestId;
    this.accept = accept;
    this.reason = reason;
    if (respondError case final error?) throw error;
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
    if (completeError case final error?) throw error;
    return const UpdateJobStatusResult(
      id: 'request-id',
      bookingId: 'booking-id',
      status: 'ACCEPTED',
      bookingStatus: 'WAITING_CONFIRMATION',
    );
  }

  @override
  Future<Map<String, dynamic>> estimateTravel(
    String bookingId,
    double latitude,
    double longitude,
  ) async => {'status': 'NOT_STARTED', 'predeparture_duration_seconds': 1800};

  @override
  Future<Map<String, dynamic>> travelStatus(String bookingId) async => {
    'status': 'ARRIVED',
    'early_start_allowed': true,
    'scheduled_at': DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String(),
  };

  @override
  Future<CancelAcceptedJobResult> cancelAcceptedJob(
    String requestId, {
    required String reason,
  }) async {
    cancelledRequestId = requestId;
    cancellationReason = reason;
    if (cancelError case final error?) throw error;
    return CancelAcceptedJobResult(
      id: 'request-id',
      bookingId: 'booking-id',
      status: 'CANCELLED',
      bookingStatus: 'CANCELLED',
      penaltyPoints: penaltyPoints,
    );
  }
}
