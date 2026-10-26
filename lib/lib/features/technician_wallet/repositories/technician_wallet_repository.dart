import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/services/secure_session_store.dart';

class TechnicianWalletRepository {
  TechnicianWalletRepository({ApiClient? apiClient, SecureSessionStore sessionStore = const SecureSessionStore()})
      : _client = apiClient ?? ApiClient.fromEnvironment(), _session = sessionStore;

  final ApiClient _client;
  final SecureSessionStore _session;

  Future<String> _token() async {
    final session = await _session.read();
    if (session == null) {
      throw const ApiException(code: 'UNAUTHENTICATED', message: 'Please sign in again.');
    }
    return session.token;
  }

  Future<Map<String, dynamic>> _data(Future<dynamic> future) async {
    final response = await future;
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid technician wallet response');
    }
    return data;
  }

  Future<Map<String, dynamic>> overview() async => _data(_client.get(
        '/technician-wallet/overview', bearerToken: await _token()));

  Future<List<Map<String, dynamic>>> transactions({int page = 1}) async {
    final data = await _data(_client.get('/technician-wallet/transactions',
        bearerToken: await _token(), queryParameters: {'page':'$page','limit':'30'}));
    return (data['items'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> topups({int page = 1}) async {
    final data = await _data(_client.get('/technician-wallet/topups',
        bearerToken: await _token(),queryParameters:{'page':'$page','limit':'30'}));
    return (data['items'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createMockWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required String idempotencyKey,
  }) async => _data(_client.post('/technician-wallet/withdrawals',
      bearerToken: await _token(), body: {
        'amount': amount, 'bankName': bankName, 'accountNumber': accountNumber,
        'accountHolder': accountHolder, 'idempotencyKey': idempotencyKey,
      }));

  Future<List<Map<String, dynamic>>> withdrawals({int page = 1}) async {
    final data = await _data(_client.get('/technician-wallet/withdrawals',
        bearerToken: await _token(), queryParameters: {'page':'$page','limit':'30'}));
    return (data['items'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createTopup({required int amount, required String method, required String idempotencyKey}) async =>
      _data(_client.post('/technician-wallet/topups',bearerToken:await _token(),body:{
        'amount':amount,'method':method,'idempotencyKey':idempotencyKey,
      }));

  Future<Map<String, dynamic>> topupDetail(String topupId) async =>
      _data(_client.get('/technician-wallet/topups/$topupId',bearerToken:await _token()));

  Future<Map<String, dynamic>> reconcile(String topupId) async =>
      _data(_client.post('/technician-wallet/topups/$topupId/reconcile',bearerToken:await _token()));
}
