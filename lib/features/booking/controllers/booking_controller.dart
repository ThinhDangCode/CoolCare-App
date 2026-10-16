import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/services/secure_session_store.dart';

class BookingAcUnit {
  BookingAcUnit({
    this.acBrandId,
    this.acModelId,
    this.description = '',
    List<String>? serviceIds,
  }) : serviceIds = serviceIds ?? [];

  String? acBrandId;
  String? acModelId;
  String description;
  final List<String> serviceIds;

  Map<String, dynamic> toJson() => {
    'acBrandId': acBrandId,
    'acModelId': acModelId,
    'description': description.trim(),
    'serviceIds': serviceIds,
  };
}

class BookingController extends ChangeNotifier {
  BookingController({
    required ApiClient apiClient,
    SecureSessionStore sessionStore = const SecureSessionStore(),
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore;

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  // CATALOG DATA
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> addresses = [];

  final Map<String, List<Map<String, dynamic>>> modelsByBrand = {};

  // BOOKING FORM
  String? customerAddressId;
  String recipientName = '';
  String recipientPhone = '';
  String description = '';
  DateTime? scheduledAt;

  final List<BookingAcUnit> units = [BookingAcUnit()];

  // STATE
  bool isLoading = false;
  bool isLoadingModels = false;
  bool isSaving = false;

  String? errorMessage;
  String? formErrorMessage;
  Map<String, dynamic>? createdBooking;

  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<String> _getToken() async {
    final session = await _sessionStore.read();

    if (session == null || session.token.isEmpty) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Please sign in to manage your bookings.',
      );
    }

    return session.token;
  }

  // LOAD INITIAL BOOKING DATA
  Future<void> loadInitialData() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    _notify();

    try {
      final token = await _getToken();

      final results = await Future.wait<dynamic>([
        _loadAllPages('/catalog/brands'),
        _loadAllPages('/catalog/services'),
        _apiClient.get('/addresses', bearerToken: token),
      ]);

      if (_disposed) return;

      brands = results[0] as List<Map<String, dynamic>>;
      services = results[1] as List<Map<String, dynamic>>;
      addresses = _extractItems(results[2]);

      if (customerAddressId == null && addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (address) => address['is_default'] == true,
          orElse: () => addresses.first,
        );

        selectAddress(defaultAddress);
      }
    } catch (error) {
      errorMessage = _errorMessage(error);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  // LOAD ALL CATALOG PAGES
  Future<List<Map<String, dynamic>>> _loadAllPages(
    String path, {
    Map<String, String> filters = const {},
  }) async {
    const pageSize = 100;
    var page = 1;

    final items = <Map<String, dynamic>>[];

    while (true) {
      final response = await _apiClient.get(
        path,
        queryParameters: {...filters, 'page': '$page', 'limit': '$pageSize'},
      );

      final currentItems = _extractItems(response);
      items.addAll(currentItems);

      final data = _extractData(response);
      final total = int.tryParse('${data['total'] ?? ''}');

      if (currentItems.isEmpty ||
          currentItems.length < pageSize ||
          (total != null && items.length >= total)) {
        break;
      }

      page++;
    }

    return items.where((item) => item['is_active'] == true).toList();
  }

  // LOAD AC MODELS BY BRAND
  Future<void> loadModels(String brandId) async {
    if (modelsByBrand.containsKey(brandId)) return;

    isLoadingModels = true;
    errorMessage = null;
    _notify();

    try {
      final models = await _loadAllPages(
        '/catalog/models',
        filters: {'brand_id': brandId},
      );

      if (_disposed) return;

      modelsByBrand[brandId] = models;
    } catch (error) {
      errorMessage = _errorMessage(error);
    } finally {
      isLoadingModels = false;
      _notify();
    }
  }

  // SELECT CUSTOMER ADDRESS
  void selectAddress(Map<String, dynamic> address) {
    customerAddressId = address['id']?.toString();
    recipientName = address['recipient_name']?.toString() ?? '';
    recipientPhone = address['phone']?.toString() ?? '';
    _notify();
  }

  // UPDATE BOOKING REQUIREMENTS
  void setDescription(String value) {
    description = value;
    _notify();
  }

  void setRecipientName(String value) {
    recipientName = value;
    _notify();
  }

  void setRecipientPhone(String value) {
    recipientPhone = value;
    _notify();
  }

  // MANAGE AC UNITS
  void addUnit() {
    if (units.length >= 20) {
      formErrorMessage = 'bookingValidationMaxUnits';
      _notify();
      return;
    }

    units.add(BookingAcUnit());
    formErrorMessage = null;
    _notify();
  }

  void removeUnit(int index) {
    if (index < 0 || index >= units.length || units.length == 1) {
      return;
    }

    units.removeAt(index);
    _notify();
  }

  // SELECT AC BRAND
  Future<void> selectBrand(int index, String? brandId) async {
    if (index < 0 || index >= units.length) return;

    units[index].acBrandId = brandId;
    units[index].acModelId = null;
    _notify();

    if (brandId != null) {
      await loadModels(brandId);
    }
  }

  // SELECT AC MODEL
  void selectModel(int index, String? modelId) {
    if (index < 0 || index >= units.length) return;

    units[index].acModelId = modelId;
    _notify();
  }

  // DESCRIBE EACH AC UNIT
  void setUnitDescription(int index, String value) {
    if (index < 0 || index >= units.length) return;

    units[index].description = value;
    _notify();
  }

  // SELECT SERVICES FOR EACH AC UNIT
  void toggleService(int index, String serviceId) {
    if (index < 0 || index >= units.length) return;

    final selectedServices = units[index].serviceIds;

    if (selectedServices.contains(serviceId)) {
      selectedServices.remove(serviceId);
    } else {
      selectedServices.add(serviceId);
    }

    _notify();
  }

  // SELECT SERVICE SCHEDULE
  void selectSchedule(DateTime value) {
    scheduledAt = value;
    _notify();
  }

  Future<void> prefillFromBooking(Map<String, dynamic> booking) async {
    final savedAddressId = booking['customerAddressId']?.toString();
    if (savedAddressId != null &&
        addresses.any(
          (address) => address['id']?.toString() == savedAddressId,
        )) {
      customerAddressId = savedAddressId;
    }

    final recipient = booking['recipient'];
    if (recipient is Map) {
      recipientName = recipient['name']?.toString() ?? recipientName;
      recipientPhone = recipient['phone']?.toString() ?? recipientPhone;
    }
    description = booking['description']?.toString() ?? '';
    scheduledAt = null;

    final rawUnits = booking['units'];
    if (rawUnits is List && rawUnits.isNotEmpty) {
      units
        ..clear()
        ..addAll(
          rawUnits.whereType<Map>().map((raw) {
            final rawServices = raw['services'];
            return BookingAcUnit(
              acBrandId: raw['ac_brand_id']?.toString(),
              acModelId: raw['ac_model_id']?.toString(),
              description: raw['description']?.toString() ?? '',
              serviceIds: rawServices is List
                  ? rawServices
                        .whereType<Map>()
                        .map((service) => service['id']?.toString() ?? '')
                        .where((id) => id.isNotEmpty)
                        .toList()
                  : <String>[],
            );
          }),
        );
      if (units.isEmpty) units.add(BookingAcUnit());
    }

    final brandIds = units
        .map((unit) => unit.acBrandId)
        .whereType<String>()
        .toSet();
    for (final brandId in brandIds) {
      await loadModels(brandId);
    }
    formErrorMessage = null;
    _notify();
  }

  // VALIDATE BOOKING FORM
  String? validateBooking() {
    if (customerAddressId == null) {
      return 'bookingValidationAddress';
    }

    if (recipientName.trim().isEmpty || recipientName.trim().length > 100) {
      return 'bookingValidationRecipientName';
    }

    if (!RegExp(r'^0[0-9]{9}$').hasMatch(recipientPhone.trim())) {
      return 'bookingValidationPhone';
    }

    if (description.trim().length > 2000) {
      return 'bookingValidationDescription';
    }

    if (scheduledAt == null || !scheduledAt!.isAfter(DateTime.now())) {
      return 'bookingValidationSchedule';
    }

    for (var index = 0; index < units.length; index++) {
      final unit = units[index];

      if (unit.description.trim().length > 2000) {
        return 'bookingValidationUnitDescription:${index + 1}';
      }

      if (unit.acModelId != null && unit.acBrandId == null) {
        return 'bookingValidationUnitBrand:${index + 1}';
      }

      if (unit.serviceIds.isEmpty) {
        return 'bookingValidationUnitService:${index + 1}';
      }
    }

    return null;
  }

  // CREATE BOOKING
  Future<bool> createBooking() async {
    if (isSaving) return false;

    formErrorMessage = validateBooking();

    if (formErrorMessage != null) {
      _notify();
      return false;
    }

    isSaving = true;
    formErrorMessage = null;
    createdBooking = null;
    _notify();

    try {
      final token = await _getToken();

      final response = await _apiClient.post(
        '/bookings',
        bearerToken: token,
        body: {
          'customerAddressId': customerAddressId,
          'recipientName': recipientName.trim(),
          'recipientPhone': recipientPhone.trim(),
          'description': description.trim(),
          'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
          'units': units.map((unit) => unit.toJson()).toList(),
        },
      );

      if (_disposed) return false;

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid booking response.');
      }

      createdBooking = data;
      return true;
    } catch (error) {
      formErrorMessage = _errorMessage(error);
      return false;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  // RESET FORM
  void resetForm() {
    customerAddressId = null;
    recipientName = '';
    recipientPhone = '';
    description = '';
    scheduledAt = null;
    createdBooking = null;
    formErrorMessage = null;

    units
      ..clear()
      ..add(BookingAcUnit());

    _notify();
  }

  // RESPONSE HELPERS
  Map<String, dynamic> _extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];

      if (data is Map<String, dynamic>) return data;
      return response;
    }

    return {};
  }

  List<Map<String, dynamic>> _extractItems(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'];

      // Address API returns the list directly in data.
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      // Other APIs may return paginated data.
      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['addresses'];

        if (items is List) {
          return items.whereType<Map<String, dynamic>>().toList();
        }
      }

      // Support responses without a data wrapper.
      final items = response['items'] ?? response['addresses'];

      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }

    return [];
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;

    if (error is FormatException) {
      return error.message;
    }

    return 'Unable to process your booking. Please try again.';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
