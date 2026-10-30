import '../localization/language_state.dart';

class ApiException implements Exception {
  const ApiException({
    required String message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
    this.fieldErrors = const {},
  }) : _message = message;

  final String _message;
  final String code;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  String get message {
    if (LanguageState.code != 'en') return _message;
    const englishByCode = <String, String>{
      'NETWORK_ERROR': 'Could not connect to the server. Check your connection and try again.',
      'REQUEST_TIMEOUT': 'The request timed out. Please try again.',
      'INVALID_RESPONSE': 'The server returned an invalid response. Please try again.',
      'API_NOT_CONFIGURED': 'The server address has not been configured.',
      'INVALID_CREDENTIALS': 'Incorrect email or password.',
      'ACCOUNT_UNAVAILABLE': 'This account is unavailable. Please contact support.',
      'EMAIL_NOT_VERIFIED': 'Please verify your email before logging in.',
      'GOOGLE_SIGN_IN_REQUIRED': 'This account uses Google. Continue with Google to log in.',
      'EMAIL_ALREADY_REGISTERED': 'This email is already registered. Please log in.',
      'SESSION_REPLACED': 'This account was signed in on another device.',
      'INVALID_TOKEN': 'Your session has expired. Please log in again.',
      'UNAUTHENTICATED': 'Please log in to continue.',
      'INVALID_OTP': 'The verification code is invalid.',
      'OTP_EXPIRED': 'The verification code has expired. Request a new one.',
      'INVALID_CURRENT_PASSWORD': 'Your current password is incorrect.',
      'PROFILE_NOT_FOUND': 'Your profile could not be found.',
      'PASSWORD_UNAVAILABLE': 'This Google account does not have a password.',
      'EMAIL_NOT_CONFIGURED': 'Email is unavailable. Please contact support.',
      'GOOGLE_NOT_CONFIGURED': 'Google sign-in is unavailable. Please contact support.',
      'INVALID_GOOGLE_TOKEN': 'Google sign-in could not be verified. Please try again.',
      'GOOGLE_TOKEN_MISSING': 'Could not get a Google verification token. Please try again.',
      'GOOGLE_SIGN_IN_canceled': 'Google sign-in was cancelled.',
      'GOOGLE_SIGN_IN_clientConfigurationError': 'Google sign-in is misconfigured. Please contact support.',
      'GOOGLE_SIGN_IN_providerConfigurationError': 'Google services are unavailable on this device. Please try again later.',
      'GOOGLE_SIGN_IN_uiUnavailable': 'Could not open the Google account picker. Please try again.',
      'GOOGLE_SIGN_IN_interrupted': 'Google sign-in was interrupted. Please try again.',
      'GOOGLE_SIGN_IN_userMismatch': 'The selected Google account does not match. Please choose another account.',
      'GOOGLE_SIGN_IN_FAILED': 'Could not sign in with Google. Please try again.',
      'INVALID_RESET_TOKEN': 'The password reset link is invalid or has expired.',
      'CLOUDINARY_NOT_CONFIGURED': 'Image uploads are unavailable. Please contact support.',
      'IMAGE_NOT_FOUND': 'The selected image could not be found. Please choose it again.',
      'INVALID_IMAGE_TYPE': 'Use a JPG, PNG or WEBP image.',
      'IMAGE_TOO_LARGE': 'The image must be 5 MB or smaller.',
      'CLOUDINARY_UPLOAD_FAILED': 'Could not upload the image. Please try again.',
      'CLOUDINARY_TIMEOUT': 'The image upload timed out. Please try again.',
      'CLOUDINARY_NETWORK_ERROR': 'Could not connect to the image service. Check your connection.',
      'DOCUMENT_NOT_FOUND': 'The selected file could not be found. Please choose it again.',
      'INVALID_DOCUMENT_TYPE': 'Use a JPG, PNG or PDF file.',
      'DOCUMENT_TOO_LARGE': 'The file must be 5 MB or smaller.',
      'DOCUMENT_UPLOAD_FAILED': 'Could not upload the file. Please try again.',
      'DOCUMENT_UPLOAD_TIMEOUT': 'The file upload timed out. Please try again.',
      'DOCUMENT_UPLOAD_NETWORK_ERROR': 'Could not connect to the upload service. Check your connection.',
    };
    final translated = englishByCode[code];
    if (translated != null) return translated;
    if (!RegExp(r'[À-ỹ]').hasMatch(_message)) return _message;
    return switch (statusCode) {
      400 => 'Please check your details and try again.',
      401 => 'Please log in again.',
      403 => 'You do not have permission to do that.',
      404 => 'The requested item could not be found.',
      409 => 'This action is no longer available. Refresh and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
