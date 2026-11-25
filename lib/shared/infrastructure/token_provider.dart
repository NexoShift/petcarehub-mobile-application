/// Lo que ApiClient necesita saber de la sesión, sin depender del BC de IAM.
///
/// IAM lo implementa (SessionStorage), así shared no importa nada de iam.
abstract interface class TokenProvider {
  String? get token;

  /// Se llama cuando la API responde 401 con un token puesto: la sesión venció.
  void onUnauthorized();
}
