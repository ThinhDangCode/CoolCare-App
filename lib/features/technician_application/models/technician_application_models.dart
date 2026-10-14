class TechnicianSkillOption {
  const TechnicianSkillOption({
    required this.id,
    required this.name,
    required this.serviceName,
  });

  factory TechnicianSkillOption.fromJson(Map<String, dynamic> json) =>
      TechnicianSkillOption(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        serviceName: json['service_name']?.toString() ?? '',
      );

  final String id;
  final String name;
  final String serviceName;
}

class TechnicianBrandOption {
  const TechnicianBrandOption({required this.id, required this.name});

  factory TechnicianBrandOption.fromJson(Map<String, dynamic> json) =>
      TechnicianBrandOption(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );

  final String id;
  final String name;
}

class TechnicianApplicationOptions {
  const TechnicianApplicationOptions({
    required this.city,
    required this.wards,
    required this.skills,
    required this.brands,
  });

  factory TechnicianApplicationOptions.fromJson(Map<String, dynamic> json) {
    final area = json['service_area'];
    return TechnicianApplicationOptions(
      city: area is Map ? area['city']?.toString() ?? '' : '',
      wards: area is Map && area['wards'] is List
          ? (area['wards'] as List).map((item) => item.toString()).toList()
          : const [],
      skills: json['skills'] is List
          ? (json['skills'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TechnicianSkillOption.fromJson)
                .toList()
          : const [],
      brands: json['brands'] is List
          ? (json['brands'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TechnicianBrandOption.fromJson)
                .toList()
          : const [],
    );
  }

  final String city;
  final List<String> wards;
  final List<TechnicianSkillOption> skills;
  final List<TechnicianBrandOption> brands;
}

class TechnicianApplicationStatus {
  const TechnicianApplicationStatus({
    required this.id,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.certifications = const [],
  });

  factory TechnicianApplicationStatus.fromJson(Map<String, dynamic> json) =>
      TechnicianApplicationStatus(
        id: json['id']?.toString() ?? '',
        status: json['verification_status']?.toString() ?? 'PENDING',
        submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
        reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
        rejectionReason: json['rejection_reason']?.toString(),
        certifications: json['certifications'] is List
            ? (json['certifications'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(TechnicianCertificationStatus.fromJson)
                  .toList()
            : const [],
      );

  final String id;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<TechnicianCertificationStatus> certifications;
}

class TechnicianCertificationStatus {
  const TechnicianCertificationStatus({
    required this.id,
    required this.name,
    required this.status,
    this.number,
    this.issuedBy,
    this.issuedDate,
    this.expiryDate,
    this.documentUrl,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  factory TechnicianCertificationStatus.fromJson(Map<String, dynamic> json) =>
      TechnicianCertificationStatus(
        id: json['id']?.toString() ?? '',
        name: json['certificate_name']?.toString() ?? 'Certification',
        number: json['certificate_number']?.toString(),
        issuedBy: json['issued_by']?.toString(),
        issuedDate: DateTime.tryParse(json['issued_date']?.toString() ?? ''),
        expiryDate: DateTime.tryParse(json['expiry_date']?.toString() ?? ''),
        documentUrl: json['document_url']?.toString(),
        status: json['verification_status']?.toString() ?? 'PENDING',
        rejectionReason: json['rejection_reason']?.toString(),
        submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
        reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      );

  final String id;
  final String name;
  final String status;
  final String? number;
  final String? issuedBy;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String? documentUrl;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
}

class TechnicianSkillInput {
  const TechnicianSkillInput({
    required this.skillId,
    required this.level,
    this.brandId,
  });

  final String skillId;
  final String level;
  final String? brandId;

  Map<String, dynamic> toJson() => {
    'skill_id': skillId,
    'ac_brand_id': brandId,
    'skill_level': level,
  };
}

class TechnicianCertificateInput {
  const TechnicianCertificateInput({
    required this.name,
    required this.imagePath,
    this.number,
    this.issuedBy,
    this.issuedDate,
    this.expiryDate,
  });

  final String name;
  final String imagePath;
  final String? number;
  final String? issuedBy;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
}

class TechnicianApplicationInput {
  const TechnicianApplicationInput({
    required this.identityNumber,
    required this.identityFrontPath,
    required this.identityBackPath,
    required this.qualificationLevel,
    required this.yearsExperience,
    required this.bio,
    required this.city,
    required this.wards,
    required this.skills,
    required this.certifications,
  });

  final String identityNumber;
  final String identityFrontPath;
  final String identityBackPath;
  final String qualificationLevel;
  final int yearsExperience;
  final String bio;
  final String city;
  final List<String> wards;
  final List<TechnicianSkillInput> skills;
  final List<TechnicianCertificateInput> certifications;
}
