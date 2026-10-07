import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    HttpClient? httpClient,
  })  : _baseUri = Uri.parse(
    baseUrl.replaceFirst(RegExp(r'/$'), ''),
  ),
        _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  // GET
  Future<dynamic> get(
      String path, {
        Map<String, String>? queryParameters,
        String? bearerToken,
      }) {
    return _request(
      'GET',
      path,
      queryParameters: queryParameters,
      bearerToken: bearerToken,
    );
  }

  // POST
  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        String? bearerToken,
      }) async {
    final response = await _request(
      'POST',
      path,
      body: body,
      bearerToken: bearerToken,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    return <String, dynamic>{};
  }

  // PUT
  Future<Map<String, dynamic>> put(
      String path, {
        Map<String, dynamic>? body,
        String? bearerToken,
      }) async {
    final response = await _request(
      'PUT',
      path,
      body: body,
      bearerToken: bearerToken,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    return <String, dynamic>{};
  }

  // PATCH
  Future<Map<String, dynamic>> patch(
      String path, {
        Map<String, dynamic>? body,
        String? bearerToken,
      }) async {
    final response = await _request(
      'PATCH',
      path,
      body: body,
      bearerToken: bearerToken,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    return <String, dynamic>{};
  }

  // DELETE
  Future<void> delete(
      String path, {
        String? bearerToken,
      }) async {
    await _request(
      'DELETE',
      path,
      bearerToken: bearerToken,
    );
  }

  // REQUEST
  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? queryParameters,
        String? bearerToken,
      }) async {
    final normalizedPath =
    path.startsWith('/') ? path.substring(1) : path;

    Uri uri = Uri.parse(
      '${_baseUri.toString()}/$normalizedPath',
    );

    if (queryParameters != null &&
        queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParameters,
        },
      );
    }

    try {
      final request = await _httpClient
          .openUrl(method, uri)
          .timeout(
        const Duration(seconds: 15),
      );

      request.headers.contentType = ContentType.json;

      request.headers.set(
        HttpHeaders.acceptHeader,
        ContentType.json.mimeType,
      );

      if (bearerToken != null &&
          bearerToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $bearerToken',
        );
      }

      if (body != null) {
        request.write(
          jsonEncode(body),
        );
      }

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final responseText =
      await utf8.decoder.bind(response).join();

      final dynamic decoded = responseText.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseText);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final payload =
        decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};

        throw _toApiException(
          response.statusCode,
          payload,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        code: 'REQUEST_TIMEOUT',
        message:
        'Kết nối quá thời gian. Vui lòng thử lại.',
      );
    } on SocketException {
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message:
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.',
      );
    } on FormatException {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message:
        'Máy chủ trả về dữ liệu không hợp lệ.',
      );
    }
  }

  // API ERROR
  ApiException _toApiException(
      int statusCode,
      Map<String, dynamic> payload,
      ) {
    final error = payload['error'];

    final errorMap =
    error is Map<String, dynamic>
        ? error
        : <String, dynamic>{};

    final details = errorMap['details'];

    final fieldErrors = <String, String>{};

    if (details is Map) {
      for (final entry in details.entries) {
        if (entry.value is String) {
          fieldErrors[entry.key.toString()] =
          entry.value as String;
        }
      }
    }

    return ApiException(
      statusCode: statusCode,
      code: errorMap['code']?.toString() ??
          'HTTP_$statusCode',
      message: errorMap['message']?.toString() ??
          'Yêu cầu không thành công.',
      fieldErrors: fieldErrors,
    );
  }
}