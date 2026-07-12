import '../../core/network/api_client.dart';

class SearchesRepository {
  SearchesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadSearchesData(String token) async {
    final searches = await _apiClient.getJsonList(
      '/searches/my-searches',
      token: token,
    );
    final results = await _apiClient.getJsonList(
      '/results/my-results',
      token: token,
    );

    List<dynamic> cities = const [];
    try {
      cities = await _apiClient.getJsonList('/geography/cities', token: token);
    } catch (_) {
      // Geography is optional for this screen. We fallback to IDs when unavailable.
    }

    return {'searches': searches, 'results': results, 'cities': cities};
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

  Future<Map<String, dynamic>> createSearch({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _apiClient.postJson('/searches/new', token: token, body: body);
  }

  Future<Map<String, dynamic>> updateSearch({
    required String token,
    required int searchId,
    required Map<String, dynamic> body,
  }) {
    return _apiClient.putJson('/searches/$searchId', token: token, body: body);
  }

  Future<void> deleteSearch({
    required String token,
    required int searchId,
  }) async {
    await _apiClient.deleteJson('/searches/$searchId', token: token);
  }
}
