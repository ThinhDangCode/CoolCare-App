class ServiceModel {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final int? estimatedDuration;
  final int? maintenanceIntervalDays;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.basePrice,
    this.estimatedDuration,
    this.maintenanceIntervalDays,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      basePrice: _parseDouble(json['base_price']),
      estimatedDuration: _parseInt(json['estimated_duration']),
      maintenanceIntervalDays:
      _parseInt(json['maintenance_interval_days']),
      isActive: json['is_active'] == true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}