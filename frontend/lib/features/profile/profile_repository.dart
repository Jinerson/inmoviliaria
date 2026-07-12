import '../../core/network/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadProfile(String token) {
    return _apiClient.getJson('/users/profile', token: token);
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) {
    return _apiClient.putJson(
      '/users/profile/change-password',
      token: token,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}
