import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/technician_application_models.dart';
import '../repositories/technician_application_repository.dart';

class TechnicianApplicationController extends ChangeNotifier {
  TechnicianApplicationController(this._repository);

  final TechnicianApplicationRepository _repository;

  TechnicianApplicationOptions? options;
  TechnicianApplicationStatus? application;
  String? errorMessage;
  bool isLoading = true;
  bool isSubmitting = false;

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.loadOptions(),
        _repository.loadStatus(),
      ]);
      options = result[0] as TechnicianApplicationOptions;
      application = result[1] as TechnicianApplicationStatus?;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Không thể tải thông tin đăng ký kỹ thuật viên.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> submit(TechnicianApplicationInput input) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      application = await _repository.submit(input);
      isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Không thể gửi hồ sơ. Vui lòng thử lại.';
    }
    isSubmitting = false;
    notifyListeners();
    return false;
  }
}
