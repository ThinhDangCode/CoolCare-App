import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

class ServiceController extends ChangeNotifier {
  ServiceController({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  bool _disposed = false;

  // ============================================================
  // DATA
  // ============================================================

  final List<ServiceModel> _allServices = [];

  List<ServiceModel> get allServices => List.unmodifiable(_allServices);

  List<ServiceModel> services = [];

  // Category vẫn giữ vì có thể dùng ở chức năng khác.
  // ServicesPage hiện tại KHÔNG dùng category để filter.
  List<ServiceCategoryModel> categories = [];

  List<Map<String, dynamic>> reviews = [];

  ServiceModel? selectedService;

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;
  bool isDetailLoading = false;

  String? errorMessage;
  String? detailErrorMessage;

  String searchKeyword = '';

  // null = All
  // service id = chỉ hiển thị service đó
  String? selectedServiceId;

  // ============================================================
  // LOAD INITIAL DATA
  // ============================================================

  Future<void> loadInitialData() async {
    isLoading = true;
    errorMessage = null;

    _notifyIfMounted();

    try {
      await _loadServicesFromApi();
      if (_disposed) return;

      // Category không phải dữ liệu chính của UI Service,
      // nên nếu API category lỗi vẫn cho phép service hiển thị.
      try {
        await _loadCategoriesFromApi();
        if (_disposed) return;
      } catch (error) {
        if (_disposed) return;
        categories = [];

        debugPrint('Unable to load service categories: $error');
      }

      _applyFilters();
    } catch (error) {
      if (_disposed) return;
      debugPrint('Unable to load services: $error');
      errorMessage = _cleanErrorMessage(error);
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notifyIfMounted();
      }
    }
  }

  // ============================================================
  // LOAD SERVICES
  // ============================================================

  Future<void> _loadServicesFromApi() async {
    final response = await _apiClient.get(ApiEndpoints.services);
    if (_disposed) return;

    final jsonList = _extractList(response);

    final loadedServices = jsonList
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .where((service) => service.isActive)
        .toList();

    _allServices
      ..clear()
      ..addAll(loadedServices);

    services = List<ServiceModel>.from(_allServices);
  }

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================

  Future<void> _loadCategoriesFromApi() async {
    final response = await _apiClient.get(ApiEndpoints.serviceCategories);
    if (_disposed) return;

    final jsonList = _extractList(response);

    categories = jsonList
        .whereType<Map<String, dynamic>>()
        .map(ServiceCategoryModel.fromJson)
        .where((category) => category.isActive)
        .toList();
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadInitialData();
  }

  // ============================================================
  // SEARCH SERVICE BY NAME
  // ============================================================

  void searchServices(String keyword) {
    searchKeyword = keyword.trim();

    if (searchKeyword.isNotEmpty) {
      selectedServiceId = null;
    }

    _applyFilters();
    _notifyIfMounted();
  }

  // ============================================================
  // FILTER BY SERVICE
  // ============================================================

  void filterByService(String? serviceId) {
    selectedServiceId = serviceId;

    // Khi chọn chip service,
    // bỏ keyword cũ để tránh 2 filter xung đột.
    searchKeyword = '';

    _applyFilters();
    _notifyIfMounted();
  }

  // ============================================================
  // CLEAR FILTER
  // ============================================================

  void clearFilters() {
    searchKeyword = '';
    selectedServiceId = null;

    services = List<ServiceModel>.from(_allServices);

    _notifyIfMounted();
  }

  // ============================================================
  // APPLY SEARCH / FILTER
  // ============================================================

  void _applyFilters() {
    Iterable<ServiceModel> result = _allServices;

    if (searchKeyword.isNotEmpty) {
      final keyword = _normalizeText(searchKeyword);

      result = result.where((service) {
        final normalizedName = _normalizeText(service.name);

        final words = normalizedName
            .split(RegExp(r'[\s/]+'))
            .where((word) => word.isNotEmpty);

        // Search theo đầu mỗi từ trong tên service
        return words.any((word) => word.startsWith(keyword));
      });
    } else if (selectedServiceId != null && selectedServiceId!.isNotEmpty) {
      result = result.where((service) => service.id == selectedServiceId);
    }

    services = result.toList();
  }

  // ============================================================
  // NORMALIZE VIETNAMESE
  // ============================================================

  String _normalizeText(String value) {
    var text = value.toLowerCase().trim();

    const replacements = <String, String>{
      // a
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',

      // e
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',

      // i
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',

      // o
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',

      // u
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',

      // y
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',

      // d
      'đ': 'd',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    // Nhiều khoảng trắng -> 1 khoảng trắng.
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }

  // ============================================================
  // SERVICE DETAIL
  // ============================================================

  Future<void> loadServiceDetail(String serviceId) async {
    final cleanId = serviceId.trim();

    selectedService = null;
    reviews = [];
    detailErrorMessage = null;

    if (cleanId.isEmpty) {
      detailErrorMessage = 'Mã dịch vụ không hợp lệ.';

      _notifyIfMounted();
      return;
    }

    isDetailLoading = true;
    _notifyIfMounted();

    try {
      final response = await _apiClient.get(
        ApiEndpoints.serviceDetail(cleanId),
      );
      if (_disposed) return;

      final data = _extractObject(response);

      if (data == null) {
        detailErrorMessage = 'Không tìm thấy dịch vụ.';
        return;
      }

      final service = ServiceModel.fromJson(data);

      if (!service.isActive) {
        detailErrorMessage = 'Dịch vụ này hiện không khả dụng.';
        return;
      }

      selectedService = service;
    } catch (error) {
      if (_disposed) return;
      detailErrorMessage = _cleanErrorMessage(error);
    } finally {
      if (!_disposed) {
        isDetailLoading = false;
        _notifyIfMounted();
      }
    }
  }

  void _notifyIfMounted() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ============================================================
  // EXTRACT LIST
  // ============================================================

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        return response['data'] as List<dynamic>;
      }

      final data = response['data'];
      if (data is Map<String, dynamic> && data['items'] is List) {
        return data['items'] as List<dynamic>;
      }

      if (response['items'] is List) {
        return response['items'] as List<dynamic>;
      }

      if (response['services'] is List) {
        return response['services'] as List<dynamic>;
      }

      if (response['categories'] is List) {
        return response['categories'] as List<dynamic>;
      }

      if (response['reviews'] is List) {
        return response['reviews'] as List<dynamic>;
      }
    }

    return [];
  }

  // ============================================================
  // EXTRACT OBJECT
  // ============================================================

  Map<String, dynamic>? _extractObject(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }

      if (response['service'] is Map<String, dynamic>) {
        return response['service'] as Map<String, dynamic>;
      }

      if (response.containsKey('id')) {
        return response;
      }
    }

    return null;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
