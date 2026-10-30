import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';

void main() {
  late HttpServer server;
  var serviceRequests = 0;
  var unauthorizedRequests = 0;

  setUp(() async {
    serviceRequests = 0;
    unauthorizedRequests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      switch (request.uri.path) {
        case '/api/health':
          request.response.write('{"data":{"status":"OK"}}');
        case '/api/services':
          serviceRequests++;
          if (serviceRequests == 1) {
            request.response.statusCode = 503;
            request.response.write('{"error":{"message":"Starting"}}');
          } else {
            request.response.write('{"data":{"items":[1]}}');
          }
        case '/api/unauthorized':
          unauthorizedRequests++;
          request.response.statusCode = 401;
          request.response.write('{"error":{"message":"Unauthorized"}}');
      }
      await request.response.close();
    });
  });

  tearDown(() async => server.close(force: true));

  test('retries one transient GET failure', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}/api');

    expect(await client.get('/services'), {
      'data': {
        'items': [1],
      },
    });
    expect(serviceRequests, 2);
  });

  test('does not retry an authorization error', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}/api');

    await expectLater(
      client.get('/unauthorized'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );
    expect(unauthorizedRequests, 1);
  });
}
