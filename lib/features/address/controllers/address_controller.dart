import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/address_model.dart';
import '../models/location_model.dart';

class AddressController extends ChangeNotifier {
  AddressController({
    required ApiClient apiClient,
    SecureSessionStore sessionStore = const SecureSessionStore(),
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore;

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;

  // DATA
  List<AddressModel> addresses = [];
  List<ProvinceModel> provinces = [];
  List<WardModel> wards = [];

  // STATE
  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool isSettingDefault = false;
  bool isLoadingProvinces = false;
  bool isLoadingWards = false;

  String? errorMessage;
  String? formErrorMessage;

  // TOKEN
  Future<String> _getToken() async {
    final session = await _sessionStore.read();

    if (session == null || session.token.isEmpty) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'You need to sign in to manage your addresses.',
      );
    }

    return session.token;
  }

  // LOAD ADDRESSES
  Future<void> loadAddresses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await _apiClient.get(
        ApiEndpoints.addresses,
        bearerToken: token,
      );

      addresses = _parseAddresses(response);
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await loadAddresses();
  }

  // CREATE ADDRESS
  Future<bool> createAddress({
    required String recipientName,
    required String phone,
    required String city,
    required String ward,
    required String addressLine,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    isSaving = true;
    formErrorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final body = <String, dynamic>{
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'city': city.trim(),
        'ward': ward.trim(),
        'address_line': addressLine.trim(),
        'is_default': isDefault,
      };

      if (latitude != null) {
        body['latitude'] = latitude;
      }

      if (longitude != null) {
        body['longitude'] = longitude;
      }

      await _apiClient.post(
        ApiEndpoints.addresses,
        bearerToken: token,
        body: body,
      );

      await _reloadAddresses();

      return true;
    } catch (error) {
      formErrorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // UPDATE ADDRESS
  Future<bool> updateAddress({
    required String addressId,
    required String recipientName,
    required String phone,
    required String city,
    required String ward,
    required String addressLine,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    isSaving = true;
    formErrorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final body = <String, dynamic>{
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'city': city.trim(),
        'ward': ward.trim(),
        'address_line': addressLine.trim(),
        'is_default': isDefault,
      };

      if (latitude != null) {
        body['latitude'] = latitude;
      }

      if (longitude != null) {
        body['longitude'] = longitude;
      }

      await _apiClient.put(
        ApiEndpoints.addressDetail(addressId),
        bearerToken: token,
        body: body,
      );

      await _reloadAddresses();

      return true;
    } catch (error) {
      formErrorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // DELETE ADDRESS
  Future<bool> deleteAddress(String addressId) async {
    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      await _apiClient.delete(
        ApiEndpoints.addressDetail(addressId),
        bearerToken: token,
      );

      await _reloadAddresses();

      return true;
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  // SET DEFAULT ADDRESS
  Future<bool> setDefaultAddress(String addressId) async {
    isSettingDefault = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      await _apiClient.patch(
        ApiEndpoints.setDefaultAddress(addressId),
        bearerToken: token,
      );

      await _reloadAddresses();

      return true;
    } catch (error) {
      errorMessage = _cleanErrorMessage(error);
      return false;
    } finally {
      isSettingDefault = false;
      notifyListeners();
    }
  }

  // LOAD PROVINCES
  Future<void> loadProvinces() async {
    isLoadingProvinces = true;
    formErrorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await _apiClient.get(
        ApiEndpoints.provinces,
        bearerToken: token,
      );

      provinces = _parseProvinces(response);
    } catch (error) {
      formErrorMessage = _cleanErrorMessage(error);
    } finally {
      isLoadingProvinces = false;
      notifyListeners();
    }
  }

  // LOAD WARDS
  Future<void> loadWards(String provinceCode) async {
    wards = [];
    isLoadingWards = true;
    formErrorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await _apiClient.get(
        ApiEndpoints.wards(provinceCode),
        bearerToken: token,
      );

      wards = _parseWards(response);
    } catch (error) {
      formErrorMessage = _cleanErrorMessage(error);
    } finally {
      isLoadingWards = false;
      notifyListeners();
    }
  }

  void clearWards() {
    wards = [];
    notifyListeners();
  }

  // INTERNAL RELOAD
  Future<void> _reloadAddresses() async {
    final token = await _getToken();

    final response = await _apiClient.get(
      ApiEndpoints.addresses,
      bearerToken: token,
    );

    addresses = _parseAddresses(response);
  }

  // PARSE ADDRESSES
  List<AddressModel> _parseAddresses(dynamic response) {
    final jsonList = _extractList(response);

    return jsonList
        .whereType<Map>()
        .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // PARSE PROVINCES
  List<ProvinceModel> _parseProvinces(dynamic response) {
    final jsonList = _extractList(response);

    return jsonList
        .whereType<Map>()
        .map((item) => ProvinceModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // PARSE WARDS
  List<WardModel> _parseWards(dynamic response) {
    final jsonList = _extractList(response);

    return jsonList
        .whereType<Map>()
        .map((item) => WardModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // EXTRACT LIST
  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'];

      if (data is List) {
        return data;
      }
    }

    if (response is Map) {
      final data = response['data'];

      if (data is List) {
        return data;
      }
    }

    return [];
  }

  // CLEAN ERROR MESSAGE
  String _cleanErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
