import '../../core/network/api_client.dart';

class ResultsRepository {
  ResultsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> loadResultsForSearch({
    required String token,
    required int searchId,
  }) async {
    final payload = await _apiClient.getJsonList(
      '/results/search/$searchId',
      token: token,
    );

    return payload.whereType<Map<String, dynamic>>().toList();
  }
}
