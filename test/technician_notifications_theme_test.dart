import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coolcare_mobile/app/theme/coolcare_theme.dart';
import 'package:coolcare_mobile/features/notifications/models/customer_notification.dart';
import 'package:coolcare_mobile/features/notifications/repositories/customer_notifications_repository.dart';
import 'package:coolcare_mobile/features/technician_portal/pages/technician_notifications_page.dart';
import 'package:coolcare_mobile/features/technician_portal/repositories/technician_notifications_repository.dart';

class _NotificationsRepository extends TechnicianNotificationsRepository {
  @override
  Future<CustomerNotificationsPageData> list({int page = 1}) async =>
      CustomerNotificationsPageData(
        items: [
          CustomerNotification(
            id: 'notification-1',
            type: 'JOB_REQUEST',
            title: 'New Job Request',
            message: 'A customer sent you a new service request for booking BK-123.',
            referenceType: 'BOOKING',
            referenceId: 'booking-1',
            bookingCode: 'BK-123',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ],
        page: 1,
        totalPages: 1,
        unreadCount: 1,
      );

  @override
  Future<void> markRead(String id) async {}
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('technician notifications use readable ${dark ? 'dark' : 'light'} theme and Vietnamese',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: CoolCareTheme.light,
        darkTheme: CoolCareTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: TechnicianNotificationsPage(repository: _NotificationsRepository()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Đánh dấu đã đọc'), findsOneWidget);
      expect(find.text('Yêu cầu công việc mới'), findsOneWidget);
      expect(find.text('Khách hàng đã gửi yêu cầu dịch vụ mới cho lịch đặt BK-123.'),
          findsOneWidget);

      final title = tester.widget<Text>(find.text('Yêu cầu công việc mới'));
      expect(title.style?.color,
          dark ? CoolCareTheme.dark.colorScheme.onSurface
              : CoolCareTheme.light.colorScheme.onSurface);

      await tester.tap(find.text('Yêu cầu công việc mới'));
      await tester.pumpAndSettle();
      expect(find.text('CHI TIẾT THÔNG BÁO'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
