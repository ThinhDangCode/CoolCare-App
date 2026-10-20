class TechnicianRatingSummary {
  const TechnicianRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
    required this.recentReviews,
  });

  factory TechnicianRatingSummary.fromJson(Map<String, dynamic> json) {
    final rawDistribution = json['distribution'];
    final distribution = <int, int>{};
    if (rawDistribution is Map) {
      for (var stars = 1; stars <= 5; stars++) {
        distribution[stars] = int.tryParse(
              rawDistribution['$stars']?.toString() ?? '',
            ) ??
            0;
      }
    }
    final rawReviews = json['recent_reviews'];
    return TechnicianRatingSummary(
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
      totalReviews:
          int.tryParse(json['total_reviews']?.toString() ?? '') ?? 0,
      distribution: distribution,
      recentReviews: rawReviews is List
          ? rawReviews
                .whereType<Map<String, dynamic>>()
                .map(TechnicianCustomerReview.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;
  final List<TechnicianCustomerReview> recentReviews;
}

class TechnicianCustomerReview {
  const TechnicianCustomerReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory TechnicianCustomerReview.fromJson(Map<String, dynamic> json) =>
      TechnicianCustomerReview(
        id: json['id']?.toString() ?? '',
        customerName: json['customer_name']?.toString() ?? '',
        rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        comment: json['comment']?.toString(),
      );

  final String id;
  final String customerName;
  final int rating;
  final DateTime? createdAt;
  final String? comment;
}
