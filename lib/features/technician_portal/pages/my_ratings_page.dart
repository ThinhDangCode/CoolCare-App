import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/technician_rating_summary.dart';
import '../repositories/technician_portal_repository.dart';

class MyRatingsPage extends StatefulWidget {
  const MyRatingsPage({required this.repository, super.key});

  final TechnicianPortalRepository repository;

  @override
  State<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  TechnicianRatingSummary? _summary;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.myRatings();
      if (mounted) setState(() => _summary = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('ratingsLoadFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      title: Text(context.tr('myRatings')),
      backgroundColor: context.appSurface,
      surfaceTintColor: Colors.transparent,
    ),
    body: _loading && _summary == null
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _summary == null
        ? _RatingsError(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: _summary!.totalReviews == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: context.appMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('noRatingsYet'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('ratingsEmptyHint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.appMuted),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null)
                        _InlineRatingsError(message: _error!, onRetry: _load),
                      _RatingOverview(summary: _summary!),
                      const SizedBox(height: 22),
                      Text(
                        context.tr('recentReviews'),
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._summary!.recentReviews.map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewCard(review: review),
                        ),
                      ),
                    ],
                  ),
          ),
  );
}

class _RatingOverview extends StatelessWidget {
  const _RatingOverview({required this.summary});
  final TechnicianRatingSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 108,
          child: Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: context.appText,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              const _Stars(rating: 5, size: 13),
              const SizedBox(height: 5),
              Text(
                context.tr('reviewCount').replaceAll(
                  '{count}',
                  '${summary.totalReviews}',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                _DistributionRow(
                  stars: stars,
                  count: summary.distribution[stars] ?? 0,
                  total: summary.totalReviews,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.stars,
    required this.count,
    required this.total,
  });
  final int stars;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            '$stars★',
            style: TextStyle(color: context.appMuted, fontSize: 10),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: total == 0 ? 0 : count / total,
              backgroundColor: context.appBorder,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: TextStyle(color: context.appMuted, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final TechnicianCustomerReview review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(context, review.createdAt),
              style: TextStyle(color: context.appMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _Stars(rating: review.rating, size: 13),
        if (review.comment?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 9),
          Text(
            review.comment!.trim(),
            style: TextStyle(
              color: context.appMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ],
    ),
  );
}

String _formatDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final language = Localizations.localeOf(context).languageCode;
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return language == 'vi'
      ? '$day/$month/${local.year}'
      : '$month/$day/${local.year}';
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.size});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var star = 1; star <= 5; star++)
        Icon(
          star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFF59E0B),
          size: size,
        ),
    ],
  );
}

class _RatingsError extends StatelessWidget {
  const _RatingsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 42, color: context.appMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('retry')),
          ),
        ],
      ),
    ),
  );
}

class _InlineRatingsError extends StatelessWidget {
  const _InlineRatingsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: context.appSurface,
    child: ListTile(
      leading: const Icon(Icons.error_outline_rounded, color: Colors.red),
      title: Text(message, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ),
  );
}
