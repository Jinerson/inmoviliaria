import '../../core/network/api_client.dart';
import 'property_draft.dart';

class GeographyOption {
  GeographyOption({required this.id, required this.name});

  final int id;
  final String name;
}

class CreatePropertyRepository {
  CreatePropertyRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<GeographyOption>> fetchCities({required String token}) async {
    final data = await _apiClient.getJsonList('/geography/cities', token: token);
    return _toOptions(data);
  }

  Future<List<GeographyOption>> fetchDistricts({
    required String token,
    required int cityId,
  }) async {
    final data = await _apiClient.getJsonList(
      '/geography/cities/$cityId/districts',
      token: token,
    );
    return _toOptions(data);
  }

  Future<List<GeographyOption>> fetchNeighborhoods({
    required String token,
    required int districtId,
  }) async {
    final data = await _apiClient.getJsonList(
      '/geography/districts/$districtId/neighborhoods',
      token: token,
    );
    return _toOptions(data);
  }

  Future<void> publishDraft({
    required String token,
    required PropertyDraft draft,
  }) async {
    final property = await _createProperty(token: token, draft: draft);
    final propertyId = _extractPropertyId(property);

    if (propertyId == null) {
      throw ApiException('No se pudo obtener el id del inmueble creado');
    }

    for (final photo in draft.photos) {
      final bytes = await photo.readAsBytes();
      await _uploadPhoto(
        token: token,
        propertyId: propertyId,
        bytes: bytes,
        fileName: photo.name,
      );
    }
  }

  Future<Map<String, dynamic>> _createProperty({
    required String token,
    required PropertyDraft draft,
  }) async {
    return _apiClient.postJson(
      '/properties/new',
      token: token,
      body: draft.toCreatePayload(),
    );
  }

  Future<void> _uploadPhoto({
    required String token,
    required int propertyId,
    required List<int> bytes,
    required String fileName,
  }) async {
    await _apiClient.postMultipartSingleFile(
      '/properties/$propertyId/upload-photos',
      token: token,
      fileField: 'photo',
      fileBytes: bytes,
      fileName: fileName,
    );
  }

  int? _extractPropertyId(Map<String, dynamic> payload) {
    final topLevelCandidates = <dynamic>[
      payload['id'],
      payload['property_id'],
      payload['propertyId'],
    ];

    for (final candidate in topLevelCandidates) {
      final parsed = _parseInt(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    final nestedContainers = <dynamic>[
      payload['property'],
      payload['data'],
      payload['result'],
      payload['created'],
    ];

    for (final container in nestedContainers) {
      if (container is Map<String, dynamic>) {
        final nestedId = _extractPropertyId(container);
        if (nestedId != null) {
          return nestedId;
        }
      }
    }

    return _findIdRecursively(payload);
  }

  int? _findIdRecursively(Map<String, dynamic> payload) {
    for (final entry in payload.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      if (key == 'id' || key == 'property_id' || key == 'propertyid') {
        final parsed = _parseInt(value);
        if (parsed != null) {
          return parsed;
        }
      }

      if (value is Map<String, dynamic>) {
        final nested = _findIdRecursively(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
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

  List<GeographyOption> _toOptions(List<dynamic> payload) {
    return payload.whereType<Map<String, dynamic>>().map((item) {
      final rawId = item['id'];
      final rawName = item['name'];

      final id = rawId is int ? rawId : int.tryParse('${rawId ?? ''}');
      final name = rawName is String ? rawName.trim() : '';

      if (id == null || name.isEmpty) {
        throw ApiException('Datos de geografia invalidos');
      }

      return GeographyOption(id: id, name: name);
    }).toList();
  }
}
