import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/infrastructure/token_provider.dart';

/// Guarda solo el token JWT, cifrado (Keychain en iOS, Keystore en Android).
///
/// Además mantiene una copia en memoria para que ApiClient lo lea sin await.
class SessionStorage implements TokenProvider {
  SessionStorage({FlutterSecureStorage? storage, bool persistent = true})
    : _storage = persistent ? (storage ?? const FlutterSecureStorage()) : null;

  static const _key = 'petcarehub.token';

  final FlutterSecureStorage? _storage;
  String? _token;

  /// Lo pone IamStore para enterarse cuando la API dice 401.
  void Function()? onSessionExpired;

  @override
  String? get token => _token;

  @override
  void onUnauthorized() => onSessionExpired?.call();

  Future<String?> read() async => _token = await _storage?.read(key: _key);

  Future<void> save(String token) async {
    _token = token;
    await _storage?.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage?.delete(key: _key);
  }
}

/// Versión en memoria para los tests (no hay Keychain/Keystore en `flutter test`).
class InMemorySessionStorage extends SessionStorage {
  InMemorySessionStorage({String? initialToken}) : _saved = initialToken, super(persistent: false);

  String? _saved;

  @override
  Future<String?> read() async {
    if (_saved != null) await super.save(_saved!);
    return token;
  }

  @override
  Future<void> save(String token) async {
    _saved = token;
    await super.save(token);
  }

  @override
  Future<void> clear() async {
    _saved = null;
    await super.clear();
  }
}
