import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/data/remote/api_client.dart';

class UserRepository {
  final _client = ApiClient().client;

  Future<UserModel> getProfile() async {
    final response = await _client.get('/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Permanently deletes the signed-in account and its server-side data.
  Future<void> deleteAccount() async {
    await _client.delete('/users/me');
  }
}
