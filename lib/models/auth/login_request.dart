class LoginRequest {
  final String email;
  final String password;
  final String? twoFactorCode;
  final String? twoFactorRecoveryCode;

  LoginRequest({
    required this.email,
    required this.password,
    this.twoFactorCode,
    this.twoFactorRecoveryCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
      if (twoFactorRecoveryCode != null)
        'twoFactorRecoveryCode': twoFactorRecoveryCode,
    };
  }
}
