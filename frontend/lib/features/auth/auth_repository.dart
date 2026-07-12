import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this.apiClient);

  static const String tokenKey = 'raices_access_token';

  final ApiClient apiClient;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.login(email: email, password: password);
    final token = response['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw ApiException('No se recibio token de autenticacion');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);

    return token;
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required String secondLastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await apiClient.register(
      body: {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'second_last_name': secondLastName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}
