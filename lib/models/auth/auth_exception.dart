class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  AuthException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.values
          .expand((errorList) => errorList as List)
          .join(', ');
      return errorMessages;
    }
    return message;
  }
}
