class ApiEndpoints {
  ApiEndpoints._();

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  // Services
  static const String services = '/services';
  static const String serviceCategories = '/service-categories';

  static String serviceDetail(String serviceId) {
    return '/services/$serviceId';
  }

  static String serviceReviews(String serviceId) {
    return '/services/$serviceId/reviews';
  }
  // ============================================================
  // ADDRESS
  // ============================================================

  static const String addresses = '/addresses';

  static String addressDetail(String addressId) {
    return '/addresses/$addressId';
  }

  static String setDefaultAddress(String addressId) {
    return '/addresses/$addressId/default';
  }

  static const String provinces = '/addresses/locations/provinces';

  static String wards(String provinceCode) {
    return '/addresses/locations/provinces/$provinceCode/wards';
  }

  // Technician partner applications
  static const String technicianApplications = '/technician-applications';
  static const String technicianApplicationOptions =
      '/technician-applications/options';
  static const String myTechnicianApplication = '/technician-applications/me';

  static const String technicianCertifications =
      '/technician-portal/certifications';

  static const String technicianSkills = '/technician-portal/skills';
  static const String technicianSkillOptions =
      '/technician-portal/skills/options';

  static const String technicianAreas = '/technician-portal/areas';
  static const String technicianAreaOptions =
      '/technician-portal/areas/options';
  static const String setAvailabilityStatus = '/technician-portal/availability';

  static String technicianSkill(String assignmentId) =>
      '/technician-portal/skills/$assignmentId';

  static String resubmitTechnicianCertification(String certificationId) =>
      '/technician-portal/certifications/$certificationId/resubmit';
}
