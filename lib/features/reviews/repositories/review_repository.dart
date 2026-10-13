import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/reviewable_booking.dart';

class ReviewRepository {
  ReviewRepository({ApiClient? apiClient, SecureSessionStore? sessionStore})
    : _apiClient = apiClient ?? _createDefaultClient(),
      _sessionStore = sessionStore ?? const SecureSessionStore();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  static ApiClient _createDefaultClient() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api',
    );

    return ApiClient(
      baseUrl: baseUrl,
      fallbackBaseUrls: const [
        'http://10.0.2.2:3000/api',
        'http://10.0.3.2:3000/api',
      ],
    );
  }

  Future<String> _accessToken() async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw StateError('Please sign in to continue.');
    }
    return session.token;
  }

  Future<List<ReviewableBooking>> getBookings() async {
    final response = await _apiClient.get(
      '/customer/bookings',
      bearerToken: await _accessToken(),
    );

    return (response['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReviewableBooking.fromJson)
        .toList();
  }

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _apiClient.post(
      '/customer/reviews',
      bearerToken: await _accessToken(),
      body: {'booking_id': bookingId, 'rating': rating, 'comment': comment},
    );
  }
}
