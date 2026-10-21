import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../../notifications/models/customer_notification.dart';
import '../../notifications/repositories/customer_notifications_repository.dart';

class TechnicianNotificationsRepository {
  TechnicianNotificationsRepository({
    ApiClient? apiClient,
    SecureSessionStore? sessionStore,
  }) : _api = apiClient ?? ApiClient.fromEnvironment(),
       _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<CustomerNotificationsPageData> list({int page = 1}) async {
    final token = await _token();
    final response = await _api.get(
      '/technician/notifications',
      bearerToken: token,
      queryParameters: {'page': '$page', 'limit': '20'},
    );
    if (response is! Map<String, dynamic> ||
        response['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid notifications response.');
    }
    final data = response['data'] as Map<String, dynamic>;
    final pagination = data['pagination'];
    if (data['items'] is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Notification list is missing.');
    }
    return CustomerNotificationsPageData(
      items: (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CustomerNotification.fromJson)
          .toList(growable: false),
      page: _int(pagination['page']),
      totalPages: _int(pagination['totalPages']),
      unreadCount: _int(pagination['unreadCount']),
    );
  }

  Future<void> markRead(String id) async {
    await _api.patch('/technician/notifications/$id/read', bearerToken: await _token());
  }

  Future<int> markAllRead() async {
    final response = await _api.post(
      '/technician/notifications/read-all',
      bearerToken: await _token(),
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid mark all as read response.');
    }
    return _int(data['updatedCount']);
  }

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Please sign in to view notifications.');
    }
    return session.token;
  }

  int _int(dynamic value) => value is num ? value.toInt() : 0;
}
