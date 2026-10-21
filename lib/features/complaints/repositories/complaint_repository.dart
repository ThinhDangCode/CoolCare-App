import '../../../core/network/api_client.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/customer_complaint.dart';

class CustomerComplaintPage {
  const CustomerComplaintPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<CustomerComplaint> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

class ComplaintRepository {
  ComplaintRepository({ApiClient? apiClient, SecureSessionStore? sessionStore})
    : _api = apiClient ?? ApiClient.fromEnvironment(),
      _session = sessionStore ?? const SecureSessionStore();

  final ApiClient _api;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null || session.token.isEmpty) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return session.token;
  }

  Future<CustomerComplaintPage> list({
    String status = 'ALL',
    int page = 1,
  }) async {
    final response = await _api.get(
      '/customer/complaints',
      bearerToken: await _token(),
      queryParameters: {'status': status, 'limit': '20', 'page': '$page'},
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) {
      throw const FormatException('Invalid complaints response.');
    }
    final parsedItems = items
        .whereType<Map>()
        .map(
          (item) => CustomerComplaint.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final total = data is Map<String, dynamic>
        ? (data['total'] as num?)?.toInt() ?? parsedItems.length
        : parsedItems.length;
    return CustomerComplaintPage(
      items: parsedItems,
      total: total,
      page:
          (data is Map<String, dynamic> ? data['page'] as num? : null)
              ?.toInt() ??
          page,
      limit:
          (data is Map<String, dynamic> ? data['limit'] as num? : null)
              ?.toInt() ??
          20,
    );
  }

  Future<CustomerComplaint> get(String id) async {
    final response = await _api.get(
      '/customer/complaints/$id',
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map) {
      throw const FormatException('Invalid complaint response.');
    }
    return CustomerComplaint.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CustomerComplaint> submit({
    required String bookingId,
    required String type,
    required String subject,
    required String description,
  }) async {
    final response = await _api.post(
      '/customer/complaints',
      bearerToken: await _token(),
      body: {
        'booking_id': bookingId,
        'type': type,
        'subject': subject,
        'description': description,
      },
    );
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid complaint response.');
    }
    return CustomerComplaint.fromJson(Map<String, dynamic>.from(data));
  }
}
