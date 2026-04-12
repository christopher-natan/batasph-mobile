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
