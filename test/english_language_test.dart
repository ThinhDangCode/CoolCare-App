import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:coolcare_mobile/core/localization/language_state.dart';
import 'package:coolcare_mobile/core/network/api_exception.dart';
import 'package:coolcare_mobile/features/services/models/service_model.dart';
import 'package:coolcare_mobile/features/services/widgets/service_card.dart';

void main() {
  test('API errors follow the selected language', () {
    const error = ApiException(
      code: 'INVALID_CREDENTIALS',
      message: 'Email hoặc mật khẩu không đúng.',
      statusCode: 401,
    );
    LanguageState.code = 'en';
    expect(error.message, 'Incorrect email or password.');
    LanguageState.code = 'vi';
    expect(error.message, 'Email hoặc mật khẩu không đúng.');
    LanguageState.code = 'en';
  });

  testWidgets('service card uses English catalog text when English is selected',
      (tester) async {
    const service = ServiceModel(
      id: 'service-1',
      categoryId: 'category-1',
      name: 'Kiểm tra/chẩn đoán',
      description:
          'Kiểm tra tình trạng vận hành, nguồn điện, luồng gió và xác định nguyên nhân sự cố trước khi đề xuất phương án xử lý.',
      basePrice: 100000,
      isActive: true,
    );
    Widget app(String language) => MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: ServiceCard(
          service: service,
          onDetails: () {},
          onBookNow: () {},
        ),
      ),
    );

    await tester.pumpWidget(app('en'));
    expect(find.text('Inspection and diagnosis'), findsOneWidget);
    expect(find.textContaining('Check operation, power and airflow'), findsOneWidget);
    expect(find.text('Kiểm tra/chẩn đoán'), findsNothing);

    await tester.pumpWidget(app('vi'));
    expect(find.text('Kiểm tra/chẩn đoán'), findsOneWidget);
  });
}
