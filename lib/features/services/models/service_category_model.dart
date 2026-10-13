class ServiceCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isActive,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}
