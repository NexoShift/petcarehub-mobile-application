/// Configuración por entorno. Se cambia sin tocar código con --dart-define:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
///
/// 10.0.2.2 es la PC vista desde el emulador de Android (localhost sería el propio emulador).
class Environment {
  const Environment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://petcarehub-api.kindwave-02283cc0.westus2.azurecontainerapps.io/api/v1',
  );

  /// Azure apaga el contenedor cuando no hay tráfico (minReplicas 0); la primera
  /// petición puede tardar en "despertarlo", por eso el timeout es generoso.
  static const Duration requestTimeout = Duration(seconds: 30);
}
