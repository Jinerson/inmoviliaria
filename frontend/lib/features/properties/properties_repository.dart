import '../../core/network/api_client.dart';

class PropertiesRepository {
  PropertiesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadPropertiesData(String token) async {
    final properties = await _apiClient.getJsonList(
      '/properties/my-properties',
      token: token,
    );
    final results = await _apiClient.getJsonList(
      '/results/my-results',
      token: token,
    );

    return {
      'properties': properties,
      'results': results,
    };
  }

  Future<List<dynamic>> loadCities({required String token}) {
    return _apiClient.getJsonList('/geography/cities', token: token);
  }

  Future<List<dynamic>> loadDistricts({
    required String token,
    required int cityId,
  }) {
    return _apiClient.getJsonList(
      '/geography/cities/$cityId/districts',
      token: token,
    );
  }

  Future<List<dynamic>> loadNeighborhoods({
    required String token,
    required int districtId,
  }) {
    return _apiClient.getJsonList(
      '/geography/districts/$districtId/neighborhoods',
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateProperty({
    required String token,
    required int propertyId,
    required Map<String, dynamic> body,
  }) {
    return _apiClient.putJson('/properties/$propertyId', token: token, body: body);
  }

  Future<void> deleteProperty({
    required String token,
    required int propertyId,
  }) async {
    await _apiClient.deleteJson('/properties/$propertyId', token: token);
  }
}
