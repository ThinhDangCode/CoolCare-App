import '../../../core/network/api_client.dart';
import '../models/blog_article.dart';

class BlogRepository {
  BlogRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? _createDefaultClient();

  final ApiClient _apiClient;

  static ApiClient _createDefaultClient() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api',
    );

    return ApiClient(
      baseUrl: baseUrl,
      fallbackBaseUrls: const [
        'http://10.0.2.2:3000/api',
        'http://10.0.3.2:3000/api',
      ],
    );
  }

  Future<List<BlogArticle>> getPublishedBlogs({String search = ''}) async {
    final keyword = search.trim();
    final query = keyword.isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(keyword)}';
    final response = await _apiClient.get('/customer/blogs$query');
    final data = response['data'] as Map<String, dynamic>? ?? const {};

    return (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BlogArticle.fromJson)
        .toList();
  }

  Future<BlogArticle> getBlogDetail(String id) async {
    final response = await _apiClient.get('/customer/blogs/$id');
    return BlogArticle.fromJson(response['data'] as Map<String, dynamic>);
  }
}
