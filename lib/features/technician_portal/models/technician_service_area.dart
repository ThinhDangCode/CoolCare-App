class TechnicianServiceArea {
  const TechnicianServiceArea({
    required this.city,
    required this.ward,
    this.id,
  });

  factory TechnicianServiceArea.fromJson(Map<String, dynamic> json) =>
      TechnicianServiceArea(
        id: json['id']?.toString(),
        city: json['city']?.toString() ?? '',
        ward: json['ward']?.toString() ?? '',
      );

  final String? id;
  final String city;
  final String ward;

  Map<String, dynamic> toJson() => {'city': city, 'ward': ward};
}

class TechnicianAreaOptions {
  const TechnicianAreaOptions({required this.city, required this.wards});

  factory TechnicianAreaOptions.fromJson(Map<String, dynamic> json) {
    final wards = json['wards'];
    return TechnicianAreaOptions(
      city: json['city']?.toString() ?? '',
      wards: wards is List
          ? wards
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
    );
  }

  final String city;
  final List<String> wards;
}
