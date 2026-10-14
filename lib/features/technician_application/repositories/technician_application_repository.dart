import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cloudinary_image_uploader.dart';
import '../../auth/services/secure_session_store.dart';
import '../models/technician_application_models.dart';

class TechnicianApplicationRepository {
  TechnicianApplicationRepository({
    required ApiClient apiClient,
    SecureSessionStore sessionStore = const SecureSessionStore(),
    CloudinaryImageUploader? imageUploader,
  }) : _apiClient = apiClient,
       _sessionStore = sessionStore,
       _imageUploader =
           imageUploader ?? CloudinaryImageUploader.fromEnvironment();

  final ApiClient _apiClient;
  final SecureSessionStore _sessionStore;
  final CloudinaryImageUploader _imageUploader;

  Future<String> _token() async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    return session.token;
  }

  Future<TechnicianApplicationOptions> loadOptions() async {
    final response = await _apiClient.get(
      ApiEndpoints.technicianApplicationOptions,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Không tải được dữ liệu đăng ký kỹ thuật viên.',
      );
    }
    return TechnicianApplicationOptions.fromJson(data);
  }

  Future<TechnicianApplicationStatus?> loadStatus() async {
    final response = await _apiClient.get(
      ApiEndpoints.myTechnicianApplication,
      bearerToken: await _token(),
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    return data is Map<String, dynamic>
        ? TechnicianApplicationStatus.fromJson(data)
        : null;
  }

  Future<TechnicianApplicationStatus> submit(
    TechnicianApplicationInput input,
  ) async {
    final frontUrl = await _imageUploader.uploadImage(
      input.identityFrontPath,
      targetFolder: 'coolcare/technician-applications/identity',
    );
    final backUrl = await _imageUploader.uploadImage(
      input.identityBackPath,
      targetFolder: 'coolcare/technician-applications/identity',
    );
    final certificates = <Map<String, dynamic>>[];
    for (final certificate in input.certifications) {
      final documentUrl = await _imageUploader.uploadImage(
        certificate.imagePath,
        targetFolder: 'coolcare/technician-applications/certificates',
      );
      certificates.add({
        'certificate_name': certificate.name.trim(),
        'certificate_number': certificate.number?.trim(),
        'issued_by': certificate.issuedBy?.trim(),
        'issued_date': _dateValue(certificate.issuedDate),
        'expiry_date': _dateValue(certificate.expiryDate),
        'document_url': documentUrl,
      });
    }

    final response = await _apiClient.post(
      ApiEndpoints.technicianApplications,
      bearerToken: await _token(),
      body: {
        'identity_number': input.identityNumber.trim(),
        'identity_front_url': frontUrl,
        'identity_back_url': backUrl,
        'qualification_level': input.qualificationLevel,
        'years_experience': input.yearsExperience,
        'bio': input.bio.trim(),
        'areas': input.wards
            .map((ward) => {'city': input.city, 'ward': ward})
            .toList(),
        'skills': input.skills.map((skill) => skill.toJson()).toList(),
        'certifications': certificates,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ không trả về trạng thái hồ sơ.',
      );
    }
    return TechnicianApplicationStatus.fromJson(data);
  }

  String? _dateValue(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
