import 'dart:async';

import 'package:coolcare_mobile/features/notifications/models/customer_notification.dart';
import 'package:coolcare_mobile/features/notifications/repositories/customer_notifications_repository.dart';
import 'package:coolcare_mobile/features/notifications/widgets/foreground_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('only new unread notifications pop up across routes and expire', (
    tester,
  ) async {
    final existing = _notification('Existing notification', 0);
    final repository = _Inbox()..items = [existing];
    final user = ValueNotifier<String?>('customer');
    addTearDown(user.dispose);
    await tester.pumpWidget(_app(repository, user));
    await tester.pump();
    expect(find.text(existing.title), findsNothing);

    await tester.tap(find.text('Open technician screen'));
    await tester.pumpAndSettle();
    expect(find.text('Unread: 1'), findsOneWidget);

    // The oldest arrival shares its timestamp with the baseline and appears
    // on the next page. A notification already read elsewhere is skipped.
    repository.items = [
      _notification('Already read', 2, isRead: true),
      _notification('Second arrival', 1),
      _notification('First arrival', 0),
      existing,
    ];
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Unread: 3'), findsOneWidget);
    expect(find.text('First arrival'), findsOneWidget);
    expect(find.text('Second arrival'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('First arrival'), findsNothing);
    expect(find.text('Second arrival'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
    expect(find.text('Unread: 3'), findsOneWidget);
  });

  testWidgets('logging out clears popups and ignores an in-flight response', (
    tester,
  ) async {
    final repository = _Inbox();
    final user = ValueNotifier<String?>('first-account');
    addTearDown(user.dispose);
    await tester.pumpWidget(_app(repository, user));
    await tester.pump();

    repository.items = [_notification('First account popup', 1)];
    await tester.pump(const Duration(seconds: 4));
    await ForegroundNotifications.refresh(tester.element(find.byType(_Badge)));
    await tester.pump();
    expect(find.text('First account popup'), findsOneWidget);

    final response = Completer<CustomerNotificationsPageData>();
    repository.nextResponse = response.future;
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('First account popup'), findsOneWidget);
    user.value = null;
    await tester.pump();
    expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);

    response.complete(
      const CustomerNotificationsPageData(
        items: [],
        page: 1,
        totalPages: 1,
        unreadCount: 10,
      ),
    );
    await tester.pump();
    expect(find.text('Unread: 0'), findsOneWidget);
  });
}

Widget _app(_Inbox repository, ValueNotifier<String?> user) {
  return MaterialApp(
    builder: (context, child) => ValueListenableBuilder<String?>(
      valueListenable: user,
      child: child,
      builder: (_, userId, child) => ForegroundNotifications(
        userId: userId,
        repository: repository,
        child: child!,
      ),
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Badge(),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Center(child: _Badge())),
                  ),
                ),
                child: const Text('Open technician screen'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) =>
      Text('Unread: ${ForegroundNotifications.unreadCountOf(context)}');
}

class _Inbox extends CustomerNotificationsRepository {
  List<CustomerNotification> items = [];
  Future<CustomerNotificationsPageData>? nextResponse;

  @override
  Future<CustomerNotificationsPageData> list({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final response = nextResponse;
    nextResponse = null;
    if (response != null) return response;
    const pageSize = 2;
    return CustomerNotificationsPageData(
      items: items.skip((page - 1) * pageSize).take(pageSize).toList(),
      page: page,
      totalPages: (items.length / pageSize).ceil(),
      unreadCount: items.where((item) => !item.isRead).length,
    );
  }
}

CustomerNotification _notification(
  String title,
  int second, {
  bool isRead = false,
}) {
  return CustomerNotification(
    id: title,
    type: 'BOOKING',
    title: title,
    message: 'A message for $title',
    referenceType: null,
    referenceId: null,
    bookingCode: null,
    isRead: isRead,
    createdAt: DateTime.utc(2026, 11, 7, 12, 0, second),
  );
}
