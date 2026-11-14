import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
import 'package:coolcare_mobile/features/auth/models/auth_user.dart';
import 'package:coolcare_mobile/features/auth/services/secure_session_store.dart';
import 'package:coolcare_mobile/features/blogs/models/blog_article.dart';
import 'package:coolcare_mobile/features/blogs/repositories/blog_repository.dart';
import 'package:coolcare_mobile/features/chat/chat_repository.dart';
import 'package:coolcare_mobile/features/notifications/repositories/customer_notifications_repository.dart';
import 'package:coolcare_mobile/features/payments/repositories/payment_repository.dart';
import 'package:coolcare_mobile/features/quotations/repositories/quotation_repository.dart';
import 'package:coolcare_mobile/features/reviews/repositories/review_repository.dart';
import 'package:coolcare_mobile/features/technician_wallet/repositories/technician_wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Blog Article UTCID02 uses fallback author and invalid date', () {
    final article = BlogArticle.fromJson({
      'id': 'b2',
      'title': 'Care',
      'published_at': 'invalid',
    });
    expect(article.author, 'CoolCare');
    expect(article.publishedAt, isNull);
  });

  test('Quotation List UTCID02 rejects a non-list data field', () async {
    final repository = QuotationRepository(
      apiClient: _StubClient(getPayload: {'data': 'invalid'}),
      sessionStore: const _StubStore(),
    );
    await expectLater(repository.list('bk1'), throwsA(isA<TypeError>()));
  });

  test('Quotation Create UTCID02 rejects a non-map result', () async {
    final repository = QuotationRepository(
      apiClient: _StubClient(postPayload: {'data': []}),
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.create('bk1', type: 'REPAIR', items: const []),
      throwsA(isA<TypeError>()),
    );
  });

  test('Quotation Send UTCID02 propagates an API failure', () async {
    final client = _StubClient(
      postError: const ApiException(message: 'Send denied'),
    );
    final repository = QuotationRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.send('q1'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'Send denied'),
      ),
    );
    expect(client.lastPath, '/quotations/q1/send');
    expect(client.lastBody, isEmpty);
  });

  test('Quotation Respond UTCID02 sends DECLINE decision', () async {
    final client = _StubClient();
    final repository = QuotationRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await repository.respond('q1', 'DECLINE');
    expect(client.lastPath, '/quotations/q1/respond');
    expect(client.lastBody, {'decision': 'DECLINE'});
  });

  test('Wallet Technician Name UTCID02 rejects a blank name', () async {
    final repository = TechnicianWalletRepository(
      sessionStore: const _StubStore(fullName: '  '),
    );
    await expectLater(
      repository.signedInTechnicianName(),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'PROFILE_MISSING'),
      ),
    );
  });

  test('Wallet Overview UTCID02 rejects non-map data', () async {
    final repository = _wallet({'data': []});
    await expectLater(repository.overview(), throwsA(isA<FormatException>()));
  });

  test('Wallet Transactions UTCID02 skips non-map items', () async {
    final repository = _wallet({
      'data': {
        'items': [
          'invalid',
          {'id': 'tx2'},
        ],
      },
    });
    final rows = await repository.transactions();
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'tx2');
  });

  test('Wallet Topup UTCID02 rejects missing data', () async {
    final repository = TechnicianWalletRepository(
      apiClient: _StubClient(postPayload: {}),
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.createTopup(
        amount: 200000,
        method: 'BANK',
        idempotencyKey: 'k2',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('Wallet Withdraw UTCID02 rejects non-map data', () async {
    final repository = TechnicianWalletRepository(
      apiClient: _StubClient(postPayload: {'data': []}),
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.stripeWithdraw(amount: 100000, idempotencyKey: 'k2'),
      throwsA(isA<FormatException>()),
    );
  });

  test('Wallet Reconcile UTCID02 rejects missing data', () async {
    final repository = TechnicianWalletRepository(
      apiClient: _StubClient(postPayload: {}),
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.reconcile('tp1'),
      throwsA(isA<FormatException>()),
    );
  });

  test('Blog Detail API UTCID02 rejects missing data', () async {
    final repository = BlogRepository(apiClient: _StubClient(getPayload: {}));
    await expectLater(
      repository.getBlogDetail('b2'),
      throwsA(isA<TypeError>()),
    );
  });

  test('Chat Rooms API UTCID02 rejects a non-list response', () async {
    final repository = ChatRepository(
      api: _StubClient(getPayload: {'data': {}}),
      sessions: const _StubStore(),
    );
    await expectLater(repository.rooms(), throwsA(isA<FormatException>()));
  });

  test('Notification Mark Read UTCID02 propagates an API failure', () async {
    final client = _StubClient(
      patchError: const ApiException(message: 'Mark denied'),
    );
    final repository = CustomerNotificationsRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.markRead('n2'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'Mark denied'),
      ),
    );
    expect(client.lastPath, '/customer/notifications/n2/read');
  });

  test('Payment History API UTCID02 rejects page zero', () async {
    final client = _StubClient();
    final repository = PaymentRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.history(page: 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(client.lastPath, isNull);
  });

  test('Payment Checkout API UTCID02 rejects a non-map result', () async {
    final repository = PaymentRepository(
      apiClient: _StubClient(postPayload: {'data': []}),
      sessionStore: const _StubStore(),
    );
    await expectLater(repository.checkout('p2'), throwsA(isA<TypeError>()));
  });

  test('Payment Cash API UTCID02 propagates an API failure', () async {
    final client = _StubClient(
      postError: const ApiException(message: 'Cash denied'),
    );
    final repository = PaymentRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.confirmCash('p2'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', 'Cash denied'),
      ),
    );
    expect(client.lastPath, '/payments/p2/confirm-cash');
  });

  test('Review Delete API UTCID02 propagates an API failure', () async {
    final client = _StubClient(
      deleteError: const ApiException(message: 'Delete denied'),
    );
    final repository = ReviewRepository(
      apiClient: client,
      sessionStore: const _StubStore(),
    );
    await expectLater(
      repository.deleteReview('r2'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Delete denied',
        ),
      ),
    );
    expect(client.lastPath, '/customer/reviews/r2');
  });
}

TechnicianWalletRepository _wallet(Map<String, dynamic> payload) =>
    TechnicianWalletRepository(
      apiClient: _StubClient(getPayload: payload),
      sessionStore: const _StubStore(),
    );

class _StubStore extends SecureSessionStore {
  const _StubStore({this.fullName = 'Tech An'});
  final String fullName;

  @override
  Future<AuthSession?> read() async => AuthSession(
    token: 'test-token',
    user: AuthUser(
      id: 'tech-1',
      email: 'tech@example.test',
      fullName: fullName,
      role: 'TECHNICIAN',
    ),
  );
}

class _StubClient extends ApiClient {
  _StubClient({
    this.getPayload,
    this.postPayload,
    this.postError,
    this.patchError,
    this.deleteError,
  }) : super(baseUrl: 'http://localhost');

  final dynamic getPayload;
  final Map<String, dynamic>? postPayload;
  final ApiException? postError;
  final ApiException? patchError;
  final ApiException? deleteError;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    lastPath = path;
    return getPayload ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastBody = body;
    if (postError case final error?) throw error;
    return postPayload ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    lastPath = path;
    if (patchError case final error?) throw error;
    return <String, dynamic>{};
  }

  @override
  Future<void> delete(String path, {String? bearerToken}) async {
    lastPath = path;
    if (deleteError case final error?) throw error;
  }
}
