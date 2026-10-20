import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';

class QuotationRepository {
  QuotationRepository({ApiClient? apiClient, SecureSessionStore? sessionStore})
      : _api = apiClient ?? ApiClient.fromEnvironment(),
        _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) throw StateError('Vui lòng đăng nhập.');
    return session.token;
  }

  Future<List<Map<String, dynamic>>> list(String bookingId) async {
    final result = await _api.get('/quotations/bookings/$bookingId', bearerToken: await _token());
    return (result['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create(String bookingId, {required String type,
    required List<Map<String, dynamic>> items, String? issueDescription, String? note,
    num partsAmount = 0}) async {
    final result = await _api.post('/quotations/bookings/$bookingId', bearerToken: await _token(), body: {
      'type': type, 'items': items, 'issueDescription': issueDescription,
      'note': note, 'partsAmount': partsAmount,
    });
    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<void> send(String quotationId) async {
    await _api.post('/quotations/$quotationId/send', bearerToken: await _token(), body: {});
  }

  Future<void> respond(String quotationId, String decision) async {
    await _api.post('/quotations/$quotationId/respond', bearerToken: await _token(), body: {'decision': decision});
  }
}
