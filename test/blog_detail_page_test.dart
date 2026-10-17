import 'package:coolcare_mobile/app/theme/coolcare_theme.dart';
import 'package:coolcare_mobile/features/blogs/models/blog_article.dart';
import 'package:coolcare_mobile/features/blogs/pages/blog_pages.dart';
import 'package:coolcare_mobile/features/blogs/repositories/blog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'blog detail renders markdown blocks instead of flattening them',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const article = BlogArticle(
        id: 'article-1',
        title: 'Hướng dẫn sử dụng máy lạnh',
        content: '''Mở đầu bài viết.

## 1. Kiểm tra chế độ vận hành
Đặt nhiệt độ ở mức **24–26°C**.

- Đóng kín cửa phòng
- Vệ sinh lưới lọc

1. Tắt nguồn điện
2. Kiểm tra thiết bị''',
        author: 'CoolCare',
        publishedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          theme: CoolCareTheme.light,
          home: BlogDetailPage(
            articleId: article.id,
            repository: _BlogRepository(article),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('1. Kiểm tra chế độ vận hành', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Đóng kín cửa phòng', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Vệ sinh lưới lọc', findRichText: true), findsOneWidget);
      expect(find.text('Tắt nguồn điện', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('24–26°C', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('##', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _BlogRepository extends BlogRepository {
  _BlogRepository(this.article);

  final BlogArticle article;

  @override
  Future<BlogArticle> getBlogDetail(String id) async => article;
}
