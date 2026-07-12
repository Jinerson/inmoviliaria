import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final UnauthorizedCallback? onUnauthorized;

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final normalizedBody = _normalizeWriteMap({
      'username': email,
      'password': password,
    });

    final response = await _http.post(
      _uri('/auth/login'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: normalizedBody.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> register({
    required Map<String, dynamic> body,
  }) async {
    final response = await _http.post(
      _uri('/users/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(_normalizeWriteMap(body)),
    );

    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _http.post(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_normalizeWriteMap(body)),
    );
    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _http.patch(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_normalizeWriteMap(body)),
    );
    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _http.put(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_normalizeWriteMap(body)),
    );
    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    required String token,
  }) async {
    final response = await _http.delete(
      _uri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> postMultipartSingleFile(
    String path, {
    required String token,
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers['Authorization'] = 'Bearer $token';

    if (fields != null && fields.isNotEmpty) {
      final normalizedFields = _normalizeWriteMap(fields);
      request.fields.addAll(
        normalizedFields.map((key, value) => MapEntry(key, value.toString())),
      );
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      ),
    );

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    return _asJsonMap(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String token,
  }) async {
    final response = await _http.get(
      _uri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _asJsonMap(response);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    required String token,
  }) async {
    final response = await _http.get(
      _uri(path),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _asJsonList(response);
  }

  Map<String, dynamic> _asJsonMap(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException();
    }

    final body = response.body;
    String message = 'Error de red (${response.statusCode})';

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is String) {
          message = decoded['detail'] as String;
        }
      }
    } catch (_) {
      message = body.isNotEmpty ? body : message;
    }

    throw ApiException(message);
  }

  List<dynamic> _asJsonList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException();
    }

    throw ApiException('Error de red (${response.statusCode})');
  }

  Map<String, dynamic> _normalizeWriteMap(Map<String, dynamic> input) {
    return input.map(
      (key, value) => MapEntry(key, _normalizeWriteValue(value, key: key)),
    );
  }

  dynamic _normalizeWriteValue(dynamic value, {String? key}) {
    if (value is String) {
      if (key != null && _isPasswordField(key)) {
        return value;
      }
      return value.toLowerCase();
    }

    if (value is Map<String, dynamic>) {
      return value.map(
        (childKey, childValue) => MapEntry(
          childKey,
          _normalizeWriteValue(childValue, key: childKey),
        ),
      );
    }

    if (value is List) {
      return value.map((item) => _normalizeWriteValue(item)).toList();
    }

    return value;
  }

  bool _isPasswordField(String key) {
    return key.toLowerCase().contains('password');
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  
  final String message;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Sesion expirada');
}
