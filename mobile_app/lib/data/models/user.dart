import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Role model
@JsonSerializable()
class Role {
  final int id;
  final String name;
  final int level;
  final String? description;

  Role({
    required this.id,
    required this.name,
    required this.level,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);

  Map<String, dynamic> toJson() => _$RoleToJson(this);
}

/// User model
@JsonSerializable()
class User {
  final int id;
  final String email;
  final String username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'email_verified')
  final bool emailVerified;
  final Role role;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    required this.isActive,
    required this.emailVerified,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isAdmin => role.level >= 2;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    return username;
  }
}

/// Login request model
@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'login_or_email')
  final String loginOrEmail;
  final String password;

  LoginRequest({
    required this.loginOrEmail,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// Register request model
@JsonSerializable()
class RegisterRequest {
  final String email;
  final String username;
  final String password;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    this.firstName,
    this.lastName,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

/// Auth response model
@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
