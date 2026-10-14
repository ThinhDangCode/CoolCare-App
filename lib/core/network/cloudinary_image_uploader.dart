import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class CloudinaryImageUploader {
  const CloudinaryImageUploader({
    required this.cloudName,
    required this.uploadPreset,
    this.folder = 'coolcare/profile-photos',
  });

  factory CloudinaryImageUploader.fromEnvironment() =>
      const CloudinaryImageUploader(
        cloudName: String.fromEnvironment(
          'CLOUDINARY_CLOUD_NAME',
          defaultValue: 'da36bkpx5',
        ),
        uploadPreset: String.fromEnvironment(
          'CLOUDINARY_UPLOAD_PRESET',
          defaultValue: 'coolcare_profile',
        ),
      );

  final String cloudName;
  final String uploadPreset;
  final String folder;

  Future<String> uploadProfilePhoto(String imagePath) async {
    return uploadImage(imagePath, targetFolder: folder);
  }

  Future<String> uploadImage(
    String imagePath, {
    String targetFolder = 'coolcare/technician-applications',
  }) async {
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) {
      throw const ApiException(
        code: 'CLOUDINARY_NOT_CONFIGURED',
        message: 'Cloudinary chưa được cấu hình cho ứng dụng.',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw const ApiException(
        code: 'IMAGE_NOT_FOUND',
        message: 'Không tìm thấy ảnh đã chọn. Vui lòng chọn lại ảnh.',
      );
    }

    final extension = imagePath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (contentType == null) {
      throw const ApiException(
        code: 'INVALID_IMAGE_TYPE',
        message: 'Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP.',
      );
    }
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiException(
        code: 'IMAGE_TOO_LARGE',
        message: 'Ảnh không được vượt quá 5 MB.',
      );
    }

    final boundary = 'coolcare-${DateTime.now().microsecondsSinceEpoch}';
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${Uri.encodeComponent(cloudName.trim())}/image/upload',
    );
    final client = HttpClient();

    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );

      void addField(String name, String value) {
        request.add(
          utf8.encode(
            '--$boundary\r\n'
            'Content-Disposition: form-data; name="$name"\r\n\r\n'
            '$value\r\n',
          ),
        );
      }

      addField('upload_preset', uploadPreset.trim());
      addField('folder', targetFolder);

      final fileName = file.uri.pathSegments.last.replaceAll('"', '');
      request.add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'
          'Content-Type: $contentType\r\n\r\n',
        ),
      );
      await request.addStream(file.openRead());
      request.add(utf8.encode('\r\n--$boundary--\r\n'));

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final responseText = await utf8.decoder.bind(response).join();
      final decoded = responseText.isEmpty ? null : jsonDecode(responseText);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final secureUrl = payload['secure_url']?.toString();
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          secureUrl == null ||
          secureUrl.isEmpty) {
        final cloudinaryError = payload['error'];
        final cloudinaryMessage = cloudinaryError is Map<String, dynamic>
            ? cloudinaryError['message']?.toString()
            : null;
        throw ApiException(
          statusCode: response.statusCode,
          code: 'CLOUDINARY_UPLOAD_FAILED',
          message: cloudinaryMessage ?? 'Không thể tải ảnh lên Cloudinary.',
        );
      }
      return secureUrl;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        code: 'CLOUDINARY_TIMEOUT',
        message: 'Tải ảnh quá thời gian. Vui lòng thử lại.',
      );
    } on SocketException {
      throw const ApiException(
        code: 'CLOUDINARY_NETWORK_ERROR',
        message: 'Không thể kết nối Cloudinary. Vui lòng kiểm tra mạng.',
      );
    } on FormatException {
      throw const ApiException(
        code: 'CLOUDINARY_INVALID_RESPONSE',
        message: 'Cloudinary trả về dữ liệu không hợp lệ.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> uploadDocument(
    String filePath, {
    String targetFolder = 'coolcare/technician-certifications',
  }) async {
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) {
      throw const ApiException(
        code: 'CLOUDINARY_NOT_CONFIGURED',
        message: 'Cloudinary chưa được cấu hình cho ứng dụng.',
      );
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ApiException(
        code: 'DOCUMENT_NOT_FOUND',
        message: 'Không tìm thấy tệp đã chọn. Vui lòng chọn lại.',
      );
    }
    final extension = filePath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => null,
    };
    if (contentType == null) {
      throw const ApiException(
        code: 'INVALID_DOCUMENT_TYPE',
        message: 'Chỉ hỗ trợ tệp JPG, PNG hoặc PDF.',
      );
    }
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiException(
        code: 'DOCUMENT_TOO_LARGE',
        message: 'Tệp minh chứng không được vượt quá 5 MB.',
      );
    }
    final boundary = 'coolcare-${DateTime.now().microsecondsSinceEpoch}';
    final resourceType = extension == 'pdf' ? 'raw' : 'image';
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${Uri.encodeComponent(cloudName.trim())}/$resourceType/upload',
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType('multipart', 'form-data', parameters: {'boundary': boundary});
      void addField(String name, String value) => request.add(utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="$name"\r\n\r\n$value\r\n',
      ));
      addField('upload_preset', uploadPreset.trim());
      addField('folder', targetFolder);
      final fileName = file.uri.pathSegments.last.replaceAll('"', '');
      request.add(utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$fileName"\r\nContent-Type: $contentType\r\n\r\n',
      ));
      await request.addStream(file.openRead());
      request.add(utf8.encode('\r\n--$boundary--\r\n'));
      final response = await request.close().timeout(const Duration(seconds: 45));
      final responseText = await utf8.decoder.bind(response).join();
      final decoded = responseText.isEmpty ? null : jsonDecode(responseText);
      final payload = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      final secureUrl = payload['secure_url']?.toString();
      if (response.statusCode < 200 || response.statusCode >= 300 || secureUrl == null || secureUrl.isEmpty) {
        throw ApiException(
          statusCode: response.statusCode,
          code: 'DOCUMENT_UPLOAD_FAILED',
          message: 'Không thể tải tệp minh chứng lên.',
        );
      }
      return secureUrl;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(code: 'DOCUMENT_UPLOAD_TIMEOUT', message: 'Tải tệp quá thời gian. Vui lòng thử lại.');
    } on SocketException {
      throw const ApiException(code: 'DOCUMENT_UPLOAD_NETWORK_ERROR', message: 'Không thể tải tệp. Vui lòng kiểm tra mạng.');
    } finally {
      client.close(force: true);
    }
  }
}
