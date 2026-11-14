import 'package:coolcare_mobile/core/network/api_client.dart';
import 'package:coolcare_mobile/features/services/controllers/service_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _CatalogClient extends ApiClient {
  _CatalogClient() : super(baseUrl: 'http://localhost/api');

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    if (path == '/catalog/services') {
      return {
        'data': [
          {
            'id': 'repair',
            'category_id': 'repair-category',
            'name': 'Sửa chữa cơ bản',
            'base_price': 200000,
            'is_active': true,
          },
          {
            'id': 'cleaning',
            'category_id': 'cleaning-category',
            'name': 'Vệ sinh máy lạnh',
            'base_price': 150000,
            'is_active': true,
          },
        ],
      };
    }
    return {'data': []};
  }
}

class _DetailClient extends ApiClient {
  _DetailClient({this.failReviews = false}) : super(baseUrl: 'http://localhost/api');

  final bool failReviews;
  final List<String> paths = [];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    paths.add(path);
    if (path == '/catalog/services/repair') {
      return {
        'data': {
          'id': 'repair',
          'category_id': 'repair-category',
          'name': 'Sửa chữa cơ bản',
          'base_price': 200000,
          'is_active': true,
        },
      };
    }
    if (path == '/catalog/services/repair/reviews') {
      if (failReviews) throw Exception('Reviews unavailable');
      return {
        'data': [
          {'id': 'review-1', 'rating': 5, 'comment': 'Tốt'},
        ],
      };
    }
    throw StateError('Unexpected path: $path');
  }
}

void main() {
  test('service detail loads published reviews from the catalog endpoint', () async {
    final client = _DetailClient();
    final controller = ServiceController(apiClient: client);
    addTearDown(controller.dispose);

    await controller.loadServiceDetail('repair');

    expect(controller.selectedService?.id, 'repair');
    expect(controller.reviews.single['rating'], 5);
    expect(controller.detailErrorMessage, isNull);
    expect(client.paths, [
      '/catalog/services/repair',
      '/catalog/services/repair/reviews',
    ]);
  });

  test('service detail remains available when reviews fail', () async {
    final controller = ServiceController(apiClient: _DetailClient(failReviews: true));
    addTearDown(controller.dispose);

    await controller.loadServiceDetail('repair');

    expect(controller.selectedService?.id, 'repair');
    expect(controller.reviews, isEmpty);
    expect(controller.detailErrorMessage, isNull);
  });

  test(
    'search matches the displayed English name and original Vietnamese name',
    () async {
      final controller = ServiceController(apiClient: _CatalogClient());
      addTearDown(controller.dispose);
      await controller.loadInitialData();

      controller.searchServices('repair');
      expect(controller.services.map((service) => service.id), ['repair']);

      controller.searchServices('sua');
      expect(controller.services.map((service) => service.id), ['repair']);

      controller.searchServices('cleaning');
      expect(controller.services.map((service) => service.id), ['cleaning']);

      controller.searchServices('unknown');
      expect(controller.services, isEmpty);
    },
  );

  test(
    'Services Tab UTCID02 restores all services when search is cleared',
    () async {
      final controller = ServiceController(apiClient: _CatalogClient());
      addTearDown(controller.dispose);
      await controller.loadInitialData();

      controller.searchServices('repair');
      expect(controller.services.map((service) => service.id), ['repair']);
      controller.searchServices('');
      expect(controller.services.map((service) => service.id), [
        'repair',
        'cleaning',
      ]);
      expect(controller.searchKeyword, isEmpty);
    },
  );
}
