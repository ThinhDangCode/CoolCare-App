import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/services/secure_session_store.dart';
import '../pages/recommended_technicians_page.dart';

class TechnicianMatchingApiService {
  TechnicianMatchingApiService({
    ApiClient? apiClient,
    SecureSessionStore? sessionStore,
  })  : _apiClient = apiClient ?? ApiClient.fromEnvironment(),
        _sessionStore = sessionStore ?? const SecureSessionStore();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  /// Read the access token from the existing login session.
  Future<String> _getAccessToken() async {
    final session = await _sessionStore.read();

    if (session == null || session.token.isEmpty) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Please sign in to continue.',
        statusCode: 401,
      );
    }

    return session.token;
  }

  /// #39 - View Recommended Technicians
  ///
  /// GET /api/bookings/:bookingId/recommended-technicians
  Future<List<RecommendedTechnician>> getRecommendedTechnicians(
      String bookingId,
      ) async {
    if (bookingId.trim().isEmpty) {
      throw const ApiException(
        code: 'INVALID_BOOKING_ID',
        message: 'Booking ID is required.',
      );
    }

    final token = await _getAccessToken();

    final response = await _apiClient.get(
      '/bookings/${Uri.encodeComponent(bookingId)}/recommended-technicians',
      bearerToken: token,
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Invalid technician recommendation response.',
      );
    }

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Recommendation data is missing.',
      );
    }

    final items = data['items'];

    if (items is! List) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Technician list is invalid.',
      );
    }

    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Technician information is invalid.',
        );
      }

      return _parseTechnician(item);
    }).toList(growable: false);
  }

  /// #40 - Select Technician
  ///
  /// POST /api/bookings/:bookingId/technician-selection
  Future<void> selectTechnician(
      String bookingId,
      String technicianId,
      ) async {
    if (bookingId.trim().isEmpty ||
        technicianId.trim().isEmpty) {
      throw const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Booking ID and technician ID are required.',
      );
    }

    final token = await _getAccessToken();

    try {
      await _apiClient.post(
        '/bookings/${Uri.encodeComponent(bookingId)}/technician-selection',
        bearerToken: token,
        body: {
          'technicianId': technicianId,
        },
      );
    } on ApiException catch (error) {
      if (error.code == 'TECHNICIAN_UNAVAILABLE' ||
          error.code == 'TECHNICIAN_NOT_FOUND') {
        throw TechnicianUnavailableException(error.message);
      }

      rethrow;
    }
  }

  /// Convert API data into the model used by the existing page.
  RecommendedTechnician _parseTechnician(
      Map<String, dynamic> json,
      ) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';

    if (id.isEmpty || name.isEmpty) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Technician ID or name is missing.',
      );
    }

    return RecommendedTechnician(
      id: id,
      name: name,
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount']) ?? 0,
      experienceYears: _toInt(json['experienceYears']),
      about: json['about']?.toString(),
      skills: _toStringList(json['skills']),
      serviceAreas: _toStringList(json['serviceAreas']),
      matchReason: json['matchReason']?.toString(),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}