class ApiEndpoints {
  ApiEndpoints._();

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  // Services
  // Public mobile catalog. These paths mirror the backend mount at
  // `/api/catalog`; the old top-level paths do not exist on the API.
  static const String services = '/catalog/services';
  static const String serviceCategories = '/catalog/categories';

  static String serviceDetail(String serviceId) {
    return '/catalog/services/$serviceId';
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
  static const String viewJobRequests = '/technician-portal/job-requests';

  static String respondToJobRequest(String requestId) =>
      '/technician-portal/job-requests/$requestId/response';

  static String updateJobStatus(String requestId) =>
      '/technician-portal/job-requests/$requestId/status';

  static String cancelAcceptedJob(String requestId) =>
      '/technician-portal/job-requests/$requestId/cancel';

  static String updateJobAcInformation(String requestId, String unitId) =>
      '/technician-portal/job-requests/$requestId/units/$unitId/ac-information';

  static String customerAcServiceHistory(String requestId, String unitId) =>
      '/technician-portal/job-requests/$requestId/units/$unitId/service-history';

  static String technicianSkill(String assignmentId) =>
      '/technician-portal/skills/$assignmentId';

  static String resubmitTechnicianCertification(String certificationId) =>
      '/technician-portal/certifications/$certificationId/resubmit';
}
