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
}
