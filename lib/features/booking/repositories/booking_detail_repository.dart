import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';

class BookingDetailRepository {
  BookingDetailRepository({
    ApiClient? apiClient,
    SecureSessionStore? sessionStore,
  }) : _api = apiClient ?? ApiClient.fromEnvironment(),
       _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Please sign in to continue.');
    }
    return session.token;
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    final result = await _api.get('/bookings/$id', bearerToken: await _token());
    if (result['data'] is! Map) {
      throw const FormatException('Invalid booking detail response.');
    }
    return Map<String, dynamic>.from(result['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getTimeline(String id) async {
    final result = await _api.get(
      '/bookings/$id/timeline',
      bearerToken: await _token(),
    );
    if (result is! Map || result['data'] is! List) {
      throw const FormatException('Invalid booking timeline response.');
    }
    return (result['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> cancel(String id, String reason) async {
    await _api.post(
      '/bookings/$id/cancel',
      bearerToken: await _token(),
      body: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> confirmCompletion(String id) async {
    final result = await _api.post(
      '/bookings/$id/confirm-completion',
      bearerToken: await _token(),
      body: const <String, dynamic>{},
    );
    if (result['data'] is! Map) {
      throw const FormatException('Invalid completion confirmation response.');
    }
    return Map<String, dynamic>.from(result['data'] as Map);
  }
}
