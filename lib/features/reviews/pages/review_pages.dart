import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_exception.dart';
import '../models/reviewable_booking.dart';
import '../repositories/review_repository.dart';

class CustomerActivityPage extends StatefulWidget {
  const CustomerActivityPage({super.key});

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

  void _reload() => setState(() => _bookings = _repository.getBookings());

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => _reload(),
    child: ListView(
      key: const PageStorageKey('customer-bookings'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      children: [
        Text(
          context.tr('myBookings'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 5),
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
                      onReview: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => ReviewFormPage(
                              booking: booking,
                              repository: _repository,
                            ),
                          ),
                        );
                        if (changed == true) {
                          _reload();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('reviewThanks')),
                              ),
                            );
                          }
                        }
                      },
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
  const _BookingCard({required this.booking, required this.onReview});
  final ReviewableBooking booking;
  final VoidCallback onReview;

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
        const SizedBox(height: 6),
        Text(
          '${context.tr('technician')}: ${booking.technician}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: booking.canReview ? onReview : null,
            icon: const Icon(Icons.star_outline_rounded, size: 17),
            label: Text(context.tr(booking.reviewed ? 'reviewed' : 'review')),
          ),
        ),
      ],
    ),
  );
}

class ReviewFormPage extends StatefulWidget {
  const ReviewFormPage({
    required this.booking,
    required this.repository,
    super.key,
  });
  final ReviewableBooking booking;
  final ReviewRepository repository;
  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      setState(
        () => _errorMessage = 'Please select a rating from 1 to 5 stars.',
      );
      return;
    }
    final comment = _comment.text.trim();
    if (comment.length > 1000) {
      setState(
        () => _errorMessage = 'Your review cannot exceed 1,000 characters.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.submitReview(
        bookingId: widget.booking.id,
        rating: _rating,
        comment: comment.isEmpty ? null : comment,
      );
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
  Widget build(BuildContext context) => _FormScaffold(
    title: context.tr('rateService'),
    subtitle: '${widget.booking.services}\n${widget.booking.technician}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('experienceQuestion'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
            child: Text(context.tr(_saving ? 'submitting' : 'submitReview')),
          ),
        ),
      ],
    ),
  );
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), backgroundColor: context.appSurface),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoolCareColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: CoolCareColors.text,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    ),
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
      status.replaceAll('_', ' '),
      style: const TextStyle(
        color: CoolCareColors.primaryDark,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
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
