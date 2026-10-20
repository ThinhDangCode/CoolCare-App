import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';

class PaymentRepository {
  PaymentRepository({
    ApiClient? apiClient,
    SecureSessionStore? sessionStore,
  })  : _api = apiClient ?? ApiClient.fromEnvironment(),
        _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();

    if (session == null || session.token.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    return session.token;
  }

  Future<Map<String, dynamic>> summary(
      String bookingId,
      ) async {
    final result = await _api.get(
      '/payments/bookings/$bookingId',
      bearerToken: await _token(),
    );

    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<Map<String, dynamic>> confirmCharges(
      String bookingId,
      ) async {
    final result = await _api.post(
      '/payments/bookings/$bookingId/confirm-charges',
      bearerToken: await _token(),
      body: {},
    );

    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<Map<String, dynamic>> create(
      String bookingId,
      String method,
      String key,
      ) async {
    final result = await _api.post(
      '/payments/bookings/$bookingId/attempts',
      bearerToken: await _token(),
      body: {
        'method': method,
        'idempotencyKey': key,
      },
    );

    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<Map<String, dynamic>> checkout(
      String paymentId,
      ) async {
    final result = await _api.post(
      '/payments/$paymentId/checkout',
      bearerToken: await _token(),
      body: {},
    );

    return Map<String, dynamic>.from(result['data'] as Map);
  }

  // Kiểm tra giao dịch ZaloPay từ backend.
  // Không tự cập nhật SUCCESS ở Flutter.
  Future<Map<String, dynamic>> reconcileZaloPay(
      String paymentId,
      ) async {
    final result = await _api.post(
      '/payments/$paymentId/reconcile-zalopay',
      bearerToken: await _token(),
      body: {},
    );

    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<Map<String,dynamic>> technicianSummary(String bookingId) async {
    final result=await _api.get('/payments/technician/bookings/$bookingId/summary',bearerToken:await _token());
    return Map<String,dynamic>.from(result['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> cashForTechnician(
      String bookingId,
      ) async {
    final result = await _api.get(
      '/payments/technician/bookings/$bookingId',
      bearerToken: await _token(),
    );

    return (result['data'] as List)
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
    )
        .toList();
  }

  Future<void> confirmCash(
      String paymentId,
      ) async {
    await _api.post(
      '/payments/$paymentId/confirm-cash',
      bearerToken: await _token(),
      body: {},
    );
  }
}