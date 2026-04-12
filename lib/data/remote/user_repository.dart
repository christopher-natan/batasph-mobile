import 'package:dio/dio.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class UserRepository {
  final _client = ApiClient().client;

  Future<UserModel> getProfile() async {
    try {
      final response = await _client.get('/users/me/profile');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }
    }

    final response = await _client.get('/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
