import 'package:flutter/widgets.dart';

// The catalog API currently returns only Vietnamese names and descriptions.
// Keep these translations tied to exact catalog values so user-entered text is
// never altered. New catalog entries need translations from the API.
const _englishNames = <String, String>{
  'Bảo dưỡng máy lạnh': 'AC maintenance',
  'Kiểm tra/chẩn đoán': 'Inspection and diagnosis',
  'Sửa chữa cơ bản': 'Basic AC repair',
  'Vệ sinh máy lạnh': 'AC cleaning',
  'Vệ sinh máy lạnh treo tường': 'Wall-mounted AC cleaning',
};

const _englishDescriptions = <String, String>{
  'Bảo dưỡng định kỳ, vệ sinh tổng thể và kiểm tra hiệu suất nhằm duy trì khả năng làm lạnh ổn định và tiết kiệm điện.':
      'Routine maintenance, full cleaning and performance checks to keep your AC cooling efficiently.',
  'Kiểm tra tình trạng vận hành, nguồn điện, luồng gió và xác định nguyên nhân sự cố trước khi đề xuất phương án xử lý.':
      'Check operation, power and airflow to diagnose problems before recommending a repair.',
  'Xử lý các lỗi cơ bản của máy lạnh sau khi kiểm tra; chi phí linh kiện phát sinh sẽ được báo riêng để khách hàng xác nhận.':
      'Fix basic AC problems after inspection. Any replacement parts will be quoted separately for your approval.',
  'Vệ sinh dàn lạnh, lưới lọc, máng thoát nước và kiểm tra hoạt động tổng thể của máy lạnh dân dụng.':
      'Clean the indoor unit, filters and drain pan, then check the overall operation of your home AC.',
  'Vệ sinh lưới lọc, dàn lạnh, máng nước và kiểm tra luồng gió cho máy lạnh treo tường dân dụng.':
      'Clean the filters, indoor unit and drain pan, then check airflow in your wall-mounted AC.',
};

const _englishErrors = <String, String>{
  'Mã dịch vụ không hợp lệ.': 'Invalid service ID.',
  'Không tìm thấy dịch vụ.': 'Service not found.',
  'Dịch vụ này hiện không khả dụng.': 'This service is currently unavailable.',
};

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

String localizedServiceName(BuildContext context, String name) =>
    _english(context) ? _englishNames[name.trim()] ?? name : name;

String localizedServiceNames(BuildContext context, String names) => names
    .split(',')
    .map((name) => localizedServiceName(context, name.trim()))
    .join(', ');

String localizedServiceDescription(BuildContext context, String description) =>
    _english(context)
        ? _englishDescriptions[description.trim()] ?? description
        : description;

String localizedServiceError(BuildContext context, String message) {
  if (!_english(context)) return message;
  return _englishErrors[message.trim()] ??
      (RegExp(r'[À-ỹ]').hasMatch(message)
          ? 'Could not load the service. Please try again.'
          : message);
}
