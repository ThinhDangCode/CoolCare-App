import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    List<String> fallbackBaseUrls = const [],
    HttpClient? httpClient,
  }) : _baseUris = <String>{baseUrl, ...fallbackBaseUrls}
           .where((url) => url.trim().isNotEmpty)
           .map((url) => Uri.parse(url.trim().replaceFirst(RegExp(r'/$'), '')))
           .toList(growable: false),
       _httpClient = httpClient ?? HttpClient();

  final List<Uri> _baseUris;
  final HttpClient _httpClient;
  Uri? _activeBaseUri;
  Future<Uri>? _resolvingBaseUri;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) {
    return _request('POST', path, body: body, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) => _request('PATCH', path, body: body, bearerToken: bearerToken);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final baseUri = await _resolveBaseUri();
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('${baseUri.toString()}/$normalizedPath');

    try {
      final request = await _httpClient
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $bearerToken',
        );
      }
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseText = await utf8.decoder.bind(response).join();
      final decoded = responseText.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseText);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toApiException(response.statusCode, payload);
      }
      return payload;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      _activeBaseUri = null;
      throw const ApiException(
        code: 'REQUEST_TIMEOUT',
        message: 'Kết nối quá thời gian. Vui lòng thử lại.',
      );
    } on SocketException {
      _activeBaseUri = null;
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.',
      );
    } on FormatException {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ trả về dữ liệu không hợp lệ.',
      );
    }
  }

  Future<Uri> _resolveBaseUri() async {
    final activeBaseUri = _activeBaseUri;
    if (activeBaseUri != null) return activeBaseUri;
    if (_baseUris.isEmpty) {
      throw const ApiException(
        code: 'API_NOT_CONFIGURED',
        message: 'Địa chỉ máy chủ chưa được cấu hình.',
      );
    }

    final pendingResolution = _resolvingBaseUri;
    if (pendingResolution != null) return pendingResolution;

    final resolution = _findAvailableBaseUri();
    _resolvingBaseUri = resolution;
    try {
      return await resolution;
    } finally {
      _resolvingBaseUri = null;
    }
  }

  Future<Uri> _findAvailableBaseUri() async {
    for (final baseUri in _baseUris) {
      final healthUri = Uri.parse('${baseUri.toString()}/health');
      try {
        final request = await _httpClient
            .getUrl(healthUri)
            .timeout(const Duration(seconds: 2));
        request.headers.set(
          HttpHeaders.acceptHeader,
          ContentType.json.mimeType,
        );
        final response = await request.close().timeout(
          const Duration(seconds: 3),
        );
        await response.drain<void>().timeout(const Duration(seconds: 3));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _activeBaseUri = baseUri;
          return baseUri;
        }
      } on TimeoutException {
        // Try the next emulator gateway.
      } on SocketException {
        // Try the next emulator gateway.
      } on HttpException {
        // Try the next emulator gateway.
      }
    }

    throw const ApiException(
      code: 'NETWORK_ERROR',
      message: 'Không thể kết nối máy chủ qua 10.0.2.2 hoặc 10.0.3.2.',
    );
  }

  ApiException _toApiException(int statusCode, Map<String, dynamic> payload) {
    final error = payload['error'];
    final errorMap = error is Map<String, dynamic>
        ? error
        : <String, dynamic>{};
    final details = errorMap['details'];
    final fieldErrors = <String, String>{};
    if (details is Map) {
      for (final entry in details.entries) {
        if (entry.value is String) {
          fieldErrors[entry.key.toString()] = entry.value as String;
        }
      }
    }
    return ApiException(
      statusCode: statusCode,
      code: errorMap['code']?.toString() ?? 'HTTP_$statusCode',
      message: errorMap['message']?.toString() ?? 'Yêu cầu không thành công.',
      fieldErrors: fieldErrors,
    );
  }
}
