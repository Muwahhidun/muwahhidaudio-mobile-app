// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SMTPSettings _$SMTPSettingsFromJson(Map<String, dynamic> json) => SMTPSettings(
  smtpHost: json['smtp_host'] as String,
  smtpPort: (json['smtp_port'] as num).toInt(),
  smtpUsername: json['smtp_username'] as String,
  smtpPassword: json['smtp_password'] as String,
  smtpUseSsl: json['smtp_use_ssl'] as bool,
  emailFromName: json['email_from_name'] as String,
  emailFromAddress: json['email_from_address'] as String,
  frontendUrl: json['frontend_url'] as String,
);

Map<String, dynamic> _$SMTPSettingsToJson(SMTPSettings instance) =>
    <String, dynamic>{
      'smtp_host': instance.smtpHost,
      'smtp_port': instance.smtpPort,
      'smtp_username': instance.smtpUsername,
      'smtp_password': instance.smtpPassword,
      'smtp_use_ssl': instance.smtpUseSsl,
      'email_from_name': instance.emailFromName,
      'email_from_address': instance.emailFromAddress,
      'frontend_url': instance.frontendUrl,
    };

TestEmailRequest _$TestEmailRequestFromJson(Map<String, dynamic> json) =>
    TestEmailRequest(testEmail: json['test_email'] as String);

Map<String, dynamic> _$TestEmailRequestToJson(TestEmailRequest instance) =>
    <String, dynamic>{'test_email': instance.testEmail};

TestEmailResponse _$TestEmailResponseFromJson(Map<String, dynamic> json) =>
    TestEmailResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$TestEmailResponseToJson(TestEmailResponse instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};

EmailVerificationResponse _$EmailVerificationResponseFromJson(
  Map<String, dynamic> json,
) => EmailVerificationResponse(
  message: json['message'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
);

Map<String, dynamic> _$EmailVerificationResponseToJson(
  EmailVerificationResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'email': instance.email,
  'username': instance.username,
};

ResendVerificationRequest _$ResendVerificationRequestFromJson(
  Map<String, dynamic> json,
) => ResendVerificationRequest(email: json['email'] as String);

Map<String, dynamic> _$ResendVerificationRequestToJson(
  ResendVerificationRequest instance,
) => <String, dynamic>{'email': instance.email};

ResendVerificationResponse _$ResendVerificationResponseFromJson(
  Map<String, dynamic> json,
) => ResendVerificationResponse(message: json['message'] as String);

Map<String, dynamic> _$ResendVerificationResponseToJson(
  ResendVerificationResponse instance,
) => <String, dynamic>{'message': instance.message};
