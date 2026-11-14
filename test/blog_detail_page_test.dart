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

  testWidgets('Blog Detail UTCID03 renders bold inline text', (tester) async {
    await _pumpSimpleArticle(tester, '**Lưu ý**');
    final text = tester.widget<RichText>(
      find.text('Lưu ý', findRichText: true),
    );
    final span = _spanFor(text.text, 'Lưu ý')!;
    expect(span.style?.fontWeight, FontWeight.w700);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('Blog Detail UTCID04 renders italic inline text', (tester) async {
    await _pumpSimpleArticle(tester, '_Quan trọng_');
    final text = tester.widget<RichText>(
      find.text('Quan trọng', findRichText: true),
    );
    final span = _spanFor(text.text, 'Quan trọng')!;
    expect(span.style?.fontStyle, FontStyle.italic);
    expect(
      find.textContaining('_Quan trọng_', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('Blog Detail UTCID05 renders an underlined link label', (
    tester,
  ) async {
    await _pumpSimpleArticle(tester, '[Hướng dẫn](https://example.test)');
    final text = tester.widget<RichText>(
      find.text('Hướng dẫn', findRichText: true),
    );
    final span = _spanFor(text.text, 'Hướng dẫn')!;
    expect(span.style?.decoration, TextDecoration.underline);
    expect(
      find.textContaining('https://example.test', findRichText: true),
      findsNothing,
    );
  });
}

Future<void> _pumpSimpleArticle(WidgetTester tester, String content) async {
  await tester.binding.setSurfaceSize(const Size(390, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final article = BlogArticle(
    id: 'article-1',
    title: 'Test article',
    content: content,
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
}

TextSpan? _spanFor(InlineSpan root, String value) {
  if (root is! TextSpan) return null;
  if (root.text == value && root.style != null) return root;
  for (final child in root.children ?? const <InlineSpan>[]) {
    final found = _spanFor(child, value);
    if (found != null) return found;
  }
  return null;
}

class _BlogRepository extends BlogRepository {
  _BlogRepository(this.article);

  final BlogArticle article;

  @override
  Future<BlogArticle> getBlogDetail(String id) async => article;
}
