import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../domain/api_error.dart';
import '../domain/picked_image.dart';
import 'environment.dart';
import 'token_provider.dart';

/// Cliente HTTP único de la app. Hace tres cosas que ningún BC debe repetir:
/// 1. arma la URL con [Environment.apiBaseUrl];
/// 2. pone el header `Authorization: Bearer <token>` si hay sesión;
/// 3. convierte cualquier error en [ApiError].
///
/// Es el equivalente al authInterceptor + errorInterceptor del front Angular.
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required TokenProvider tokenProvider,
    String? baseUrl,
  }) : _http = httpClient,
       _tokens = tokenProvider,
       _baseUrl = baseUrl ?? Environment.apiBaseUrl;

  final http.Client _http;
  final TokenProvider _tokens;
  final String _baseUrl;

  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(uri(path, query), headers: _headers()));

  /// GET of a binary file (clinical file download): returns the raw bytes instead of JSON.
  Future<Uint8List> getBytes(String path) async {
    final response = await _execute(
      () => _http.get(uri(path), headers: {..._headers(), 'Accept': '*/*'}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
    throw _failure(response);
  }

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _http.post(uri(path), headers: _headers(json: true), body: jsonEncode(body)));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _http.put(uri(path), headers: _headers(json: true), body: jsonEncode(body)));

  /// POST multipart para los endpoints @ModelAttribute (crear perfil, mascota...).
  /// Los campos nulos no se envían. [files] van como partes de archivo.
  Future<dynamic> postMultipart(
    String path,
    Map<String, String?> fields, {
    Map<String, PickedImage> files = const {},
  }) =>
      _multipart('POST', path, fields, files);

  /// PUT multipart, para reemplazar fotos (PUT /pets/{id}/image).
  Future<dynamic> putMultipart(
    String path, {
    Map<String, String?> fields = const {},
    Map<String, PickedImage> files = const {},
  }) =>
      _multipart('PUT', path, fields, files);

  Future<dynamic> _multipart(
    String method,
    String path,
    Map<String, String?> fields,
    Map<String, PickedImage> files,
  ) {
    final request = http.MultipartRequest(method, uri(path))
      ..headers.addAll(_headers())
      ..fields.addAll({
        for (final entry in fields.entries)
          if (entry.value != null) entry.key: entry.value!,
      })
      ..files.addAll([
        for (final entry in files.entries)
          http.MultipartFile.fromBytes(
            entry.key,
            entry.value.bytes,
            filename: entry.value.fileName,
            // El backend valida el Content-Type de la parte (jpeg, png o webp).
            contentType: MediaType.parse(entry.value.mimeType),
          ),
      ]);
    return _send(() async => http.Response.fromStream(await _http.send(request)));
  }

  Map<String, String> _headers({bool json = false}) {
    final token = _tokens.token;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final response = await _execute(request);
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    throw _failure(response);
  }

  Future<http.Response> _execute(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(Environment.requestTimeout);
    } on TimeoutException {
      throw const ApiError(status: 0, message: 'El servidor tardó demasiado en responder.');
    } on http.ClientException {
      // http envuelve los errores de red (SocketException, CORS en web) en ClientException.
      throw const ApiError(status: 0, message: 'No hay conexión con el servidor.');
    }
  }

  ApiError _failure(http.Response response) {
    if (response.statusCode == 401 && _tokens.token != null) _tokens.onUnauthorized();
    return _toApiError(response.statusCode, _decode(response));
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  ApiError _toApiError(int status, dynamic body) {
    if (body is Map<String, dynamic>) {
      return ApiError(
        status: status,
        message: (body['message'] as String?) ?? 'Error $status',
        details: [for (final d in (body['details'] as List? ?? const [])) '$d'],
      );
    }
    return ApiError(status: status, message: 'Error $status');
  }
}
