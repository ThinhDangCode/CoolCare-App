import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/customer_notification.dart';

class CustomerNotificationsPageData {
  const CustomerNotificationsPageData({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.unreadCount,
  });

  final List<CustomerNotification> items;
  final int page;
  final int totalPages;
  final int unreadCount;
}

class CustomerNotificationsRepository {
  CustomerNotificationsRepository({
    ApiClient? apiClient,
    SecureSessionStore? sessionStore,
  }) : _api = apiClient ?? ApiClient.fromEnvironment(),
       _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<CustomerNotificationsPageData> list({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Please sign in to view notifications.');
    }
    final response = await _api.get(
      '/customer/notifications',
      bearerToken: session.token,
      queryParameters: {
        'page': '$page',
        'limit': '20',
        'unreadOnly': '$unreadOnly',
      },
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
    final token = await _token();
    await _api.patch('/customer/notifications/$id/read', bearerToken: token);
  }

  Future<int> markAllRead() async {
    final token = await _token();
    final response = await _api.post(
      '/customer/notifications/read-all',
      bearerToken: token,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid mark all as read response.');
    }
    final count = data['updatedCount'];
    return count is num ? count.toInt() : 0;
  }

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Please sign in to continue.');
    }
    return session.token;
  }

  int _int(dynamic value) => value is num ? value.toInt() : 0;
}
