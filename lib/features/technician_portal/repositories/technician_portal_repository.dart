import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cloudinary_image_uploader.dart';
import '../../auth/services/secure_session_store.dart';
import '../../technician_application/models/technician_application_models.dart';
import '../models/technician_dashboard.dart';
import '../models/technician_skill.dart';
import '../models/technician_service_area.dart';
import '../models/set_availability_status.dart';

class TechnicianPortalRepository {
  TechnicianPortalRepository({
    required ApiClient apiClient,
    SecureSessionStore sessionStore = const SecureSessionStore(),
    CloudinaryImageUploader? documentUploader,
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore,
       _documentUploader =
           documentUploader ?? CloudinaryImageUploader.fromEnvironment();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;
  final CloudinaryImageUploader _documentUploader;

  Future<String> _token() async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Phiên đăng nhập đã hết hạn.',
      );
    }
    return session.token;
  }

  Future<TechnicianDashboard> dashboard() async {
    final response = await _apiClient.get(
      '/technician-portal/dashboard',
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    return TechnicianDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<SetAvailabilityStatus> availabilityStatus() async {
    final response = await _apiClient.get(
      ApiEndpoints.setAvailabilityStatus,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về trạng thái nhận việc hợp lệ.',
      );
    }
    return SetAvailabilityStatus.fromJson(data);
  }

  Future<SetAvailabilityStatus> setAvailabilityStatus(bool online) async {
    final response = await _apiClient.patch(
      ApiEndpoints.setAvailabilityStatus,
      bearerToken: await _token(),
      body: {'status': online ? 'ONLINE' : 'OFFLINE'},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không xác nhận trạng thái nhận việc.',
      );
    }
    return SetAvailabilityStatus.fromJson(data);
  }

  Future<List<TechnicianSkill>> skills() async {
    final response = await _apiClient.get(
      ApiEndpoints.technicianSkills,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về danh sách kỹ năng hợp lệ.',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(TechnicianSkill.fromJson)
        .toList();
  }

  Future<List<PortalSkillOption>> skillOptions() async {
    final response = await _apiClient.get(
      ApiEndpoints.technicianSkillOptions,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final options = data is Map<String, dynamic> ? data['skills'] : null;
    if (options is! List) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về danh sách kỹ năng có thể chọn.',
      );
    }
    return options
        .whereType<Map<String, dynamic>>()
        .map(PortalSkillOption.fromJson)
        .toList();
  }

  Future<TechnicianSkill> addSkill(
    String skillId, {
    String level = 'INTERMEDIATE',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.technicianSkills,
      bearerToken: await _token(),
      body: {'skill_id': skillId, 'ac_brand_id': null, 'skill_level': level},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về kỹ năng vừa thêm.',
      );
    }
    return TechnicianSkill.fromJson(data);
  }

  Future<void> removeSkill(String assignmentId) async {
    await _apiClient.delete(
      ApiEndpoints.technicianSkill(assignmentId),
      bearerToken: await _token(),
    );
  }

  Future<TechnicianAreaOptions> areaOptions() async {
    final response = await _apiClient.get(
      ApiEndpoints.technicianAreaOptions,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về danh sách khu vực hợp lệ.',
      );
    }
    final options = TechnicianAreaOptions.fromJson(data);
    if (options.city.isEmpty || options.wards.isEmpty) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Danh sách khu vực Cần Thơ hiện không khả dụng.',
      );
    }
    return options;
  }

  Future<List<TechnicianServiceArea>> areas() async {
    final response = await _apiClient.get(
      ApiEndpoints.technicianAreas,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về khu vực đang hoạt động.',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(TechnicianServiceArea.fromJson)
        .toList();
  }

  Future<List<TechnicianServiceArea>> replaceAreas({
    required String city,
    required Iterable<String> wards,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.technicianAreas,
      bearerToken: await _token(),
      body: {
        'areas': wards
            .map(
              (ward) => TechnicianServiceArea(city: city, ward: ward).toJson(),
            )
            .toList(),
      },
    );
    final data = response['data'];
    if (data is! List) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không xác nhận khu vực vừa lưu.',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(TechnicianServiceArea.fromJson)
        .toList();
  }

  Future<TechnicianCertificationStatus> submitCertification(
    TechnicianCertificateInput input, {
    String? certificationId,
  }) async {
    if (certificationId == null) {
      await _apiClient.get(
        '${ApiEndpoints.technicianCertifications}/check-number',
        queryParameters: {
          'name': input.name.trim(),
          'issued_by': (input.issuedBy ?? '').trim(),
          'number': (input.number ?? '').trim(),
        },
        bearerToken: await _token(),
      );
    }
    final documentUrl = await _documentUploader.uploadDocument(input.imagePath);
    final body = {
      'certificate_name': input.name.trim(),
      'certificate_number': input.number?.trim(),
      'issued_by': input.issuedBy?.trim(),
      'issued_date': _dateValue(input.issuedDate),
      'expiry_date': _dateValue(input.expiryDate),
      'document_url': documentUrl,
    };
    final response = await _apiClient.post(
      certificationId == null
          ? ApiEndpoints.technicianCertifications
          : ApiEndpoints.resubmitTechnicianCertification(certificationId),
      bearerToken: await _token(),
      body: body,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về chứng chỉ vừa gửi.',
      );
    }
    return TechnicianCertificationStatus.fromJson(data);
  }

  String? _dateValue(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
