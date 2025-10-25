import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_constants.dart';
import '../../data/models/user.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._apiClient, this._storage) : super(AuthState()) {
    _checkAuth();
  }

  /// Check if user is authenticated on app start
  Future<void> _checkAuth() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        state = state.copyWith(isLoading: true);
        final user = await _apiClient.getCurrentUser();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      }
    } catch (e) {
      // Token might be expired, clear it
      await logout();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiClient.login(
        LoginRequest(email: email, password: password),
      );

      // Save tokens
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: response.accessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: response.refreshToken,
      );

      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiClient.register(
        RegisterRequest(
          email: email,
          password: password,
          username: username,
          fullName: fullName,
        ),
      );

      // Save tokens
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: response.accessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: response.refreshToken,
      );

      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    DioProvider.reset();
    state = AuthState();
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  const storage = FlutterSecureStorage();
  return AuthNotifier(apiClient, storage);
});
