class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final String code;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}
