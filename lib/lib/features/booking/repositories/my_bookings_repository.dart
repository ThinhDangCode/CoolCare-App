import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/my_booking.dart';

class MyBookingsRepository {
  MyBookingsRepository({ApiClient? apiClient, SecureSessionStore? sessionStore})
    : _apiClient = apiClient ?? ApiClient.fromEnvironment(),
      _sessionStore = sessionStore ?? const SecureSessionStore();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  Future<List<MyBooking>> getMyBookings({int page = 1, int limit = 20}) async {
    final session = await _sessionStore.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Please sign in to continue.');
    }

    final response = await _apiClient.get(
      '/bookings',
      bearerToken: session.token,
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    if (response is! Map<String, dynamic> ||
        response['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid bookings response.');
    }
    final data = response['data'] as Map<String, dynamic>;
    if (data['items'] is! List) {
      throw const FormatException('Booking list is missing.');
    }
    return (data['items'] as List)
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid booking item.');
          }
          return MyBooking.fromJson(item);
        })
        .toList(growable: false);
  }
}
