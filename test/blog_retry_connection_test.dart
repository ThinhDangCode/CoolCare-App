import 'package:coolcare_mobile/app/theme/coolcare_theme.dart';
import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
import 'package:coolcare_mobile/features/blogs/pages/blog_pages.dart';
import 'package:coolcare_mobile/features/blogs/repositories/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BlogClient extends ApiClient {
  _BlogClient(this.online) : super(baseUrl: 'http://localhost/api');

  bool online;
  int requests = 0;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    requests++;
    if (!online) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'No connection');
    }
    return {
      'data': {
        'items': [
          {
            'id': 'article-1',
            'title': 'Recovered article',
            'content': 'Available again',
            'author_name': 'CoolCare',
          },
        ],
      },
    };
  }
}

void main() {
  testWidgets('Articles retry loads after an offline request', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _BlogClient(false);
    final repository = BlogRepository(apiClient: client);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: CoolCareTheme.light,
        home: BlogListPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load articles'), findsOneWidget);
    expect(client.requests, 1);

    client.online = true;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Recovered article'), findsOneWidget);
    expect(client.requests, 2);
    expect(find.text('Could not load articles'), findsNothing);
  });
}
