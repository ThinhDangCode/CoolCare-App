import 'package:flutter/widgets.dart';

// Keep legacy English names for search. Display catalog content as authored
// in Admin instead of translating a fixed subset of entries.
const _englishNames = <String, String>{
  'Bảo dưỡng máy lạnh': 'AC maintenance',
  'Kiểm tra/chẩn đoán': 'Inspection and diagnosis',
  'Sửa chữa cơ bản': 'Basic AC repair',
  'Vệ sinh máy lạnh': 'AC cleaning',
  'Vệ sinh máy lạnh treo tường': 'Wall-mounted AC cleaning',
};

const _englishErrors = <String, String>{
  'Mã dịch vụ không hợp lệ.': 'Invalid service ID.',
  'Không tìm thấy dịch vụ.': 'Service not found.',
  'Dịch vụ này hiện không khả dụng.': 'This service is currently unavailable.',
};

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

String englishServiceName(String name) => _englishNames[name.trim()] ?? name;

// Catalog entries are authored in Admin. Display the API value unchanged.
// Do not partially translate a fixed subset of services.
String localizedServiceName(BuildContext context, String name) => name;

String localizedServiceNames(BuildContext context, String names) => names
    .split(',')
    .map((name) => localizedServiceName(context, name.trim()))
    .join(', ');

String localizedServiceDescription(BuildContext context, String description) => description;

String localizedServiceError(BuildContext context, String message) {
  if (!_english(context)) return message;
  return _englishErrors[message.trim()] ??
      (RegExp(r'[À-ỹ]').hasMatch(message)
          ? 'Could not load the service. Please try again.'
          : message);
}
