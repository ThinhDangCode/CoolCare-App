import 'package:coolcare_mobile/app/theme/coolcare_theme.dart';
import 'package:coolcare_mobile/features/reviews/models/reviewable_booking.dart';
import 'package:coolcare_mobile/features/reviews/pages/review_pages.dart';
import 'package:coolcare_mobile/features/reviews/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReviewRepository extends ReviewRepository {
  bool deleted = false;

  @override
  Future<List<ReviewableBooking>> getBookings() async => [
    ReviewableBooking(
      id: 'booking-1',
      code: 'BK-1',
      status: 'COMPLETED',
      services: 'AC repair',
      technician: 'Technician',
      reviewed: !deleted,
      reviewId: deleted ? null : 'review-1',
      reviewRating: deleted ? null : 4,
      reviewComment: deleted ? null : 'Temporary review',
      scheduledAt: null,
    ),
  ];

  @override
  Future<void> deleteReview(String reviewId) async {
    expect(reviewId, 'review-1');
    deleted = true;
  }
}

void main() {
  testWidgets('deleting a review refreshes the list without an error', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _ReviewRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: CoolCareTheme.light,
        home: Scaffold(body: CustomerActivityPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Temporary review'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete review?'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deleted, isTrue);
    expect(find.text('Temporary review'), findsNothing);
    expect(find.text('Your review has been deleted.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
