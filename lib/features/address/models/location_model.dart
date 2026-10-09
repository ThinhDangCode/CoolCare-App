class ProvinceModel {
  const ProvinceModel({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory ProvinceModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ProvinceModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class WardModel {
  const WardModel({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory WardModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return WardModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}