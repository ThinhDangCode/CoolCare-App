class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedAt,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime? publishedAt;
  final String? thumbnailUrl;

  factory BlogArticle.fromJson(Map<String, dynamic> json) => BlogArticle(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
    author: json['author_name']?.toString() ?? 'CoolCare',
    publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
    thumbnailUrl: json['thumbnail_url']?.toString(),
  );
}
