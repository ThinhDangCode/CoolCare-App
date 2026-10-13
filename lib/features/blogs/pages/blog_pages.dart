import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/blog_article.dart';
import '../repositories/blog_repository.dart';

class BlogListPage extends StatefulWidget {
  const BlogListPage({super.key, this.repository});

  final BlogRepository? repository;

  @override
  State<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<BlogArticle>> _articles;
  late final BlogRepository _repository = widget.repository ?? BlogRepository();

  @override
  void initState() {
    super.initState();
    _articles = _repository.getPublishedBlogs();
  }

  void _load() => setState(
    () => _articles = _repository.getPublishedBlogs(search: _search.text),
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      title: Text(context.tr('articles')),
      backgroundColor: context.appSurface,
      surfaceTintColor: Colors.transparent,
    ),
    body: RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text(
            context.tr('articleHelp'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 6),
          Text(context.tr('articleSubtitle')),
          const SizedBox(height: 18),
          TextField(
            controller: _search,
            maxLength: 100,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: context.tr('searchArticles'),
              filled: true,
              fillColor: context.appSurface,
              counterText: '',
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<BlogArticle>>(
            future: _articles,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  title: context.tr('unableLoadArticles'),
                  message: _errorText(snapshot.error),
                  action: _load,
                );
              }
              final articles = snapshot.data ?? const [];
              if (articles.isEmpty) {
                return _MessageState(
                  icon: Icons.article_outlined,
                  title: context.tr('noArticles'),
                  message: context.tr('noArticlesHint'),
                );
              }
              return Column(
                children: articles
                    .map(
                      (article) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ArticleCard(article: article),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final BlogArticle article;

  @override
  Widget build(BuildContext context) => Material(
    color: context.appSurface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlogDetailPage(articleId: article.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleImage(url: article.thumbnailUrl, size: 92),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COOLCARE GUIDE',
                    style: TextStyle(
                      color: CoolCareColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _plainText(article.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${_date(article.publishedAt)}  •  ${article.author}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: CoolCareColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BlogDetailPage extends StatefulWidget {
  const BlogDetailPage({required this.articleId, super.key, this.repository});
  final String articleId;
  final BlogRepository? repository;

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late Future<BlogArticle> _article;
  late final BlogRepository _repository = widget.repository ?? BlogRepository();
  @override
  void initState() {
    super.initState();
    _article = _repository.getBlogDetail(widget.articleId);
  }

  void _retry() =>
      setState(() => _article = _repository.getBlogDetail(widget.articleId));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('articleDetail')),
      backgroundColor: context.appSurface,
    ),
    body: FutureBuilder<BlogArticle>(
      future: _article,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline,
            title: context.tr('articleUnavailable'),
            message: _errorText(snapshot.error),
            action: _retry,
          );
        }
        final article = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _ArticleImage(
                  url: article.thumbnailUrl,
                  size: double.infinity,
                  height: 210,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${article.author}  •  ${_date(article.publishedAt)}',
                style: TextStyle(color: context.appMuted, fontSize: 12),
              ),
              const Divider(height: 34),
              Text(
                _plainText(article.content),
                style: TextStyle(
                  color: context.appText,
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.url, required this.size, this.height});
  final String? url;
  final double size;
  final double? height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: height ?? size,
      color: CoolCareColors.surfaceTint,
      child: const Icon(
        Icons.ac_unit_rounded,
        color: CoolCareColors.primary,
        size: 34,
      ),
    );
    if (url == null || url!.trim().isEmpty) return fallback;
    return Image.network(
      url!,
      width: size,
      height: height ?? size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 52, color: CoolCareColors.primary),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('tryAgain')),
          ),
        ],
      ],
    ),
  );
}

String _plainText(String value) => value
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _date(DateTime? value) => value == null
    ? ''
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _errorText(Object? error) => error is ApiException
    ? error.message
    : 'Please check your connection and try again.';
