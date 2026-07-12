import '../../core/network/api_client.dart';

class HomeRepository {
  HomeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadHomeData(String token) async {
    final profile = await _apiClient.getJson('/users/profile', token: token);
    final summary = await _apiClient.getJson('/summary/', token: token);
    final properties = await _apiClient.getJsonList(
      '/properties/my-properties',
      token: token,
    );
    final results = await _apiClient.getJsonList(
      '/results/my-results',
      token: token,
    );

    final neighborhoodNamesById = await _loadNeighborhoodNames(
      token: token,
      properties: properties,
    );

    return {
      'profile': profile,
      'summary': summary,
      'properties': properties,
      'results': results,
      'neighborhoodNamesById': neighborhoodNamesById,
    };
  }

  Future<Map<int, String>> _loadNeighborhoodNames({
    required String token,
    required List<dynamic> properties,
  }) async {
    final ids = <int>{};
    for (final item in properties) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final parsedId = _parseInt(item['neighborhood_id']) ??
          _parseInt(item['neighborhoodId']);
      if (parsedId != null) {
        ids.add(parsedId);
      }
    }

    if (ids.isEmpty) {
      return const {};
    }

    final namesById = <int, String>{};

    // First try direct endpoint when available.
    for (final id in ids) {
      try {
        final payload = await _apiClient.getJson(
          '/geography/neighborhoods/$id',
          token: token,
        );
        final name = payload['name'];
        if (name is String && name.trim().isNotEmpty) {
          namesById[id] = name.trim();
        }
      } catch (_) {
        // Ignore missing neighborhood names and keep graceful fallback on UI.
      }
    }

    if (namesById.length == ids.length) {
      return namesById;
    }

    // Fallback: discover neighborhoods through existing cities->districts->neighborhoods.
    try {
      final cities = await _apiClient.getJsonList('/geography/cities', token: token);
      for (final city in cities) {
        if (city is! Map<String, dynamic>) {
          continue;
        }

        final cityId = _parseInt(city['id']);
        if (cityId == null) {
          continue;
        }

        final districts = await _apiClient.getJsonList(
          '/geography/cities/$cityId/districts',
          token: token,
        );

        for (final district in districts) {
          if (district is! Map<String, dynamic>) {
            continue;
          }

          final districtId = _parseInt(district['id']);
          if (districtId == null) {
            continue;
          }

          final neighborhoods = await _apiClient.getJsonList(
            '/geography/districts/$districtId/neighborhoods',
            token: token,
          );

          for (final neighborhood in neighborhoods) {
            if (neighborhood is! Map<String, dynamic>) {
              continue;
            }

            final neighborhoodId = _parseInt(neighborhood['id']);
            final neighborhoodName = neighborhood['name'];
            if (neighborhoodId == null ||
                neighborhoodName is! String ||
                neighborhoodName.trim().isEmpty) {
              continue;
            }

            if (ids.contains(neighborhoodId)) {
              namesById[neighborhoodId] = neighborhoodName.trim();
            }
          }
        }
      }
    } catch (_) {
      // Keep partial mapping if some geography calls fail.
    }

    return namesById;
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
