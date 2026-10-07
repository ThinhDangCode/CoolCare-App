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

  static const String provinces =
      '/addresses/locations/provinces';

  static String wards(String provinceCode) {
    return '/addresses/locations/provinces/$provinceCode/wards';
  }
}