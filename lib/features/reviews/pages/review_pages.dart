import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/reviewable_booking.dart';
import '../repositories/review_repository.dart';

class CustomerActivityPage extends StatefulWidget {
  const CustomerActivityPage({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<CustomerActivityPage> createState() => _CustomerActivityPageState();
}

class _CustomerActivityPageState extends State<CustomerActivityPage> {
  final _repository = ReviewRepository();
  late Future<List<ReviewableBooking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = _repository.getBookings();
  }

  Future<void> _reload() async {
    final request = _repository.getBookings();
    if (mounted) setState(() => _bookings = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder displays the error and its retry action.
    }
  }

  Future<void> _openReviewForm(
    ReviewableBooking booking, {
    required bool editing,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(
          booking: booking,
          repository: _repository,
          existingReviewId: editing ? booking.reviewId : null,
          initialRating: editing ? booking.reviewRating : null,
          initialComment: editing ? booking.reviewComment : null,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(editing ? 'reviewUpdated' : 'reviewThanks'),
          ),
        ),
      );
    }
  }

  Future<void> _deleteReview(ReviewableBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('deleteReviewTitle')),
        content: Text(context.tr('deleteReviewConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || booking.reviewId == null) return;
    try {
      await _repository.deleteReview(booking.reviewId!);
      if (!mounted) return;
      await _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('reviewDeleted'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _reload,
    child: ListView(
      key: const PageStorageKey('customer-bookings'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      children: [
        if (widget.showHeader) ...[
          Text(
            context.tr('myBookings'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 5),
        ],
        Text(context.tr('bookingSubtitle')),
        const SizedBox(height: 18),
        FutureBuilder<List<ReviewableBooking>>(
          future: _bookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ActivityMessage(
                message: _error(snapshot.error),
                onRetry: _reload,
              );
            }
            final bookings = snapshot.data ?? const [];
            if (bookings.isEmpty) {
              return _ActivityMessage(message: context.tr('noBookings'));
            }
            return Column(
              children: bookings
                  .map(
                    (booking) => _BookingCard(
                      booking: booking,
                      onReview: booking.canReview
                          ? () => _openReviewForm(booking, editing: false)
                          : null,
                      onEdit: booking.reviewed && booking.reviewId != null
                          ? () => _openReviewForm(booking, editing: true)
                          : null,
                      onDelete: booking.reviewed && booking.reviewId != null
                          ? () => _deleteReview(booking)
                          : null,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.onReview,
    this.onEdit,
    this.onDelete,
  });
  final ReviewableBooking booking;
  final VoidCallback? onReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: context.appSurface,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                booking.code,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StatusChip(status: booking.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          booking.services,
          style: TextStyle(color: context.appText, fontWeight: FontWeight.w700),
        ),
        if (booking.scheduledAt != null) ...[
          const SizedBox(height: 7),
          Text(
            _formatBookingDate(booking.scheduledAt!),
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '${context.tr('technician')}: ${booking.technician == 'Unassigned' ? context.tr('unassigned') : booking.technician}',
          style: const TextStyle(fontSize: 12),
        ),
        if (booking.reviewed) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFEAA400),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${booking.reviewRating ?? 0}/5',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (booking.reviewComment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    booking.reviewComment!,
                    style: TextStyle(color: context.appText, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (booking.canReview || booking.reviewed) ...[
          const SizedBox(height: 14),
          if (booking.canReview)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.star_outline_rounded, size: 17),
                label: Text(context.tr('review')),
              ),
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                _ReviewedBadge(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(context.tr('editReview')),
                ),
                IconButton(
                  tooltip: context.tr('deleteReviewTitle'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  color: CoolCareColors.error,
                ),
              ],
            ),
        ],
      ],
    ),
  );
}

class ReviewFormPage extends StatefulWidget {
  const ReviewFormPage({
    required this.booking,
    required this.repository,
    this.existingReviewId,
    this.initialRating,
    this.initialComment,
    super.key,
  });
  final ReviewableBooking booking;
  final ReviewRepository repository;
  final String? existingReviewId;
  final int? initialRating;
  final String? initialComment;
  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _comment.text = widget.initialComment ?? '';
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      setState(() => _errorMessage = context.tr('ratingRequired'));
      return;
    }
    final comment = _comment.text.trim();
    if (comment.length > 1000) {
      setState(() => _errorMessage = context.tr('reviewTooLong'));
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      if (widget.existingReviewId == null) {
        await widget.repository.submitReview(
          bookingId: widget.booking.id,
          rating: _rating,
          comment: comment.isEmpty ? null : comment,
        );
      } else {
        await widget.repository.updateReview(
          reviewId: widget.existingReviewId!,
          rating: _rating,
          comment: comment.isEmpty ? null : comment,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = _error(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.tr(
          widget.existingReviewId == null ? 'rateService' : 'editReview',
        ),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewBookingSummary(booking: widget.booking),
            const SizedBox(height: 26),
            Text(
              context.tr('experienceQuestion'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFFFA000),
                    size: 38,
                  ),
                ),
              ),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  context.tr('ratingValue').replaceFirst('{rating}', '$_rating'),
                  style: TextStyle(
                    color: context.appMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _comment,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('commentOptional'),
                hintText: context.tr('commentHint'),
              ),
            ),
            if (_errorMessage != null) _FormError(_errorMessage!),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(context.tr('submitting')),
                        ],
                      )
                    : Text(
                        context.tr(
                          widget.existingReviewId == null
                              ? 'submitReview'
                              : 'saveReviewChanges',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReviewBookingSummary extends StatelessWidget {
  const _ReviewBookingSummary({required this.booking});
  final ReviewableBooking booking;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border.all(color: context.appBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.code,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.services,
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _summaryLine(
              context,
              Icons.engineering_outlined,
              '${context.tr('technician')}: ${booking.technician}',
            ),
            if (booking.scheduledAt != null) ...[
              const SizedBox(height: 7),
              _summaryLine(
                context,
                Icons.calendar_today_outlined,
                _formatBookingDate(booking.scheduledAt!),
              ),
            ],
          ],
        ),
      );

  Widget _summaryLine(BuildContext context, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: context.appMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.appMuted),
            ),
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: CoolCareColors.surfaceTint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      context.tr('bookingStatus_$status'),
      style: const TextStyle(
        color: CoolCareColors.primaryDark,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReviewedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 15, color: Color(0xFF16835D)),
            const SizedBox(width: 6),
            Text(
              context.tr('reviewed'),
              style: const TextStyle(
                color: Color(0xFF16835D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _FormError extends StatelessWidget {
  const _FormError(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CoolCareColors.error.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: const TextStyle(color: CoolCareColors.error, fontSize: 12),
    ),
  );
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 90),
    child: Column(
      children: [
        const Icon(
          Icons.event_note_outlined,
          size: 52,
          color: CoolCareColors.primary,
        ),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr('tryAgain')),
          ),
        ],
      ],
    ),
  );
}

String _error(Object? error) => error is ApiException
    ? error.message
    : error is StateError
    ? error.toString().replaceFirst('Bad state: ', '')
    : 'Something went wrong. Please try again.';

String _formatBookingDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} · ${two(local.hour)}:${two(local.minute)}';
}
