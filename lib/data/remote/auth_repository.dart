import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class AuthRepository {
  final _client = ApiClient().client;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Proves the inbox with the emailed code; the API signs the user in.
  Future<AuthResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _client.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resendVerificationCode(String email) async {
    await _client.post('/auth/resend-code', data: {'email': email});
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _client.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'password': password},
    );
  }

  Future<AuthResponse> googleAuth(String idToken) async {
    final response = await _client.post(
      '/auth/google',
      data: {'idToken': idToken},
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

class AuthResponse {
  final String accessToken;
  final UserModel user;

  const AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
