import 'package:json_annotation/json_annotation.dart';

part 'system_settings.g.dart';

/// SMTP Settings model
@JsonSerializable()
class SMTPSettings {
  @JsonKey(name: 'smtp_host')
  final String smtpHost;
  @JsonKey(name: 'smtp_port')
  final int smtpPort;
  @JsonKey(name: 'smtp_username')
  final String smtpUsername;
  @JsonKey(name: 'smtp_password')
  final String smtpPassword;
  @JsonKey(name: 'smtp_use_ssl')
  final bool smtpUseSsl;
  @JsonKey(name: 'email_from_name')
  final String emailFromName;
  @JsonKey(name: 'email_from_address')
  final String emailFromAddress;
  @JsonKey(name: 'frontend_url')
  final String frontendUrl;

  SMTPSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.smtpUseSsl,
    required this.emailFromName,
    required this.emailFromAddress,
    required this.frontendUrl,
  });

  factory SMTPSettings.fromJson(Map<String, dynamic> json) =>
      _$SMTPSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SMTPSettingsToJson(this);

  SMTPSettings copyWith({
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    bool? smtpUseSsl,
    String? emailFromName,
    String? emailFromAddress,
    String? frontendUrl,
  }) {
    return SMTPSettings(
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpUseSsl: smtpUseSsl ?? this.smtpUseSsl,
      emailFromName: emailFromName ?? this.emailFromName,
      emailFromAddress: emailFromAddress ?? this.emailFromAddress,
      frontendUrl: frontendUrl ?? this.frontendUrl,
    );
  }
}

/// Test Email Request model
@JsonSerializable()
class TestEmailRequest {
  @JsonKey(name: 'test_email')
  final String testEmail;

  TestEmailRequest({
    required this.testEmail,
  });

  factory TestEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$TestEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TestEmailRequestToJson(this);
}

/// Test Email Response model
@JsonSerializable()
class TestEmailResponse {
  final bool success;
  final String message;

  TestEmailResponse({
    required this.success,
    required this.message,
  });

  factory TestEmailResponse.fromJson(Map<String, dynamic> json) =>
      _$TestEmailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TestEmailResponseToJson(this);
}

/// Email Verification Response model
@JsonSerializable()
class EmailVerificationResponse {
  final String message;
  final String email;
  final String username;

  EmailVerificationResponse({
    required this.message,
    required this.email,
    required this.username,
  });

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$EmailVerificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmailVerificationResponseToJson(this);
}

/// Resend Verification Request model
@JsonSerializable()
class ResendVerificationRequest {
  final String email;

  ResendVerificationRequest({
    required this.email,
  });

  factory ResendVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$ResendVerificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResendVerificationRequestToJson(this);
}

/// Resend Verification Response model
@JsonSerializable()
class ResendVerificationResponse {
  final String message;

  ResendVerificationResponse({
    required this.message,
  });

  factory ResendVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$ResendVerificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ResendVerificationResponseToJson(this);
}
