class AddressModel {
  const AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.ward,
    required this.city,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String ward;
  final String city;

  final double? latitude;
  final double? longitude;

  final bool isDefault;

  // FROM JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine: json['address_line']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isDefault: json['is_default'] == true,
    );
  }

  // FULL ADDRESS
  String get fullAddress {
    return '$addressLine, $ward, $city';
  }

  // DOUBLE CONVERTER
  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
