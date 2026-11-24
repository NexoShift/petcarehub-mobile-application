/// Error uniforme que devuelve la API (mismo formato que ErrorResource del backend).
///
/// Las vistas nunca ven un `http.Response`: solo ven [ApiError].
class ApiError implements Exception {
  const ApiError({required this.status, required this.message, this.details = const []});

  /// 0 cuando no hubo respuesta (sin internet, servidor apagado o timeout).
  final int status;
  final String message;
  final List<String> details;

  bool get isNetworkError => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;

  @override
  String toString() => 'ApiError($status): $message';
}
