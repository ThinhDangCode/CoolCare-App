class TechnicianSkill {
  const TechnicianSkill({
    required this.id,
    required this.skillId,
    required this.name,
    required this.serviceName,
    required this.level,
    required this.isAvailable,
    this.brandId,
    this.brandName,
  });

  factory TechnicianSkill.fromJson(Map<String, dynamic> json) =>
      TechnicianSkill(
        id: json['id']?.toString() ?? '',
        skillId: json['skill_id']?.toString() ?? '',
        name: json['skill_name']?.toString() ?? '',
        serviceName: json['service_name']?.toString() ?? '',
        level: json['skill_level']?.toString() ?? 'BEGINNER',
        brandId: json['ac_brand_id']?.toString(),
        brandName: json['brand_name']?.toString(),
        isAvailable: json['is_available'] != false,
      );

  final String id;
  final String skillId;
  final String name;
  final String serviceName;
  final String level;
  final String? brandId;
  final String? brandName;
  final bool isAvailable;
}

class PortalSkillOption {
  const PortalSkillOption({
    required this.id,
    required this.name,
    required this.serviceName,
  });

  factory PortalSkillOption.fromJson(Map<String, dynamic> json) =>
      PortalSkillOption(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        serviceName: json['service_name']?.toString() ?? '',
      );

  final String id;
  final String name;
  final String serviceName;
}
