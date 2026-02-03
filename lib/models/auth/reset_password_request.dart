class ResetPasswordRequest {
  final String email;
  final String resetCode;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.resetCode,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'resetCode': resetCode,
      'newPassword': newPassword,
    };
  }
}
