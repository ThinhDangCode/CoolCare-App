import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
import 'package:coolcare_mobile/features/ac_history/models/customer_ac_history.dart';
import 'package:coolcare_mobile/features/auth/models/auth_user.dart';
import 'package:coolcare_mobile/features/auth/services/secure_session_store.dart';
import 'package:coolcare_mobile/features/payments/models/payment_invoice.dart';
import 'package:coolcare_mobile/features/technician_portal/repositories/technician_portal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC History Page UTCID04 rejects missing pagination', () {
    expect(
      () => AcHistoryPage.fromJson({'unit': {}, 'items': []}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid AC service history response.',
        ),
      ),
    );
  });

  test('Payment Invoice UTCID04 ignores non-map items', () {
    final invoice = PaymentInvoice.fromJson({
      'items': [null, 'bad'],
    });
    expect(invoice.items, isEmpty);
  });

  test('Payment Invoice UTCID05 defaults zero quantity to one', () {
    final invoice = PaymentInvoice.fromJson({
      'items': [
        {'quantity': 0, 'unitPrice': 100000, 'totalPrice': 100000},
      ],
    });
    expect(invoice.items, hasLength(1));
    expect(invoice.items.single.quantity, 1);
  });

  test('Tech Job Requests API UTCID04 rejects a non-map item', () async {
    final repository = TechnicianPortalRepository(
      apiClient: _StubApiClient(
        getPayload: {
          'data': {
            'items': ['bad'],
          },
        },
      ),
      sessionStore: const _StubSessionStore(),
    );
    await expectLater(
      repository.viewJobRequests(),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
      ),
    );
  });

  test('Tech Respond API UTCID04 rejects an unsupported status', () async {
    final repository = TechnicianPortalRepository(
      apiClient: _StubApiClient(
        patchPayload: {
          'data': {'status': 'UNKNOWN', 'booking': <String, dynamic>{}},
        },
      ),
      sessionStore: const _StubSessionStore(),
    );
    await expectLater(
      repository.respondToJobRequest('request-id', accept: true),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
      ),
    );
  });
}

class _StubApiClient extends ApiClient {
  _StubApiClient({this.getPayload, this.patchPayload})
    : super(baseUrl: 'http://localhost');

  final dynamic getPayload;
  final Map<String, dynamic>? patchPayload;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async => getPayload;

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async => patchPayload ?? <String, dynamic>{};
}

class _StubSessionStore extends SecureSessionStore {
  const _StubSessionStore();

  @override
  Future<AuthSession?> read() async => const AuthSession(
    token: 'test-token',
    user: AuthUser(
      id: 'tech-id',
      email: 'tech@example.test',
      fullName: 'Technician',
      role: 'TECHNICIAN',
    ),
  );
}
