import 'package:flutter/foundation.dart';

import '../../shared/domain/api_error.dart';
import '../domain/model/account_type.dart';
import '../domain/model/user_session.dart';
import '../domain/repositories/auth_repository.dart';
import '../infrastructure/session_storage.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Capa application de IAM: estado de la sesión y casos de uso.
///
/// Las vistas llaman a estos métodos; nunca usan AuthApi ni http directamente.
/// go_router escucha este store (es un ChangeNotifier) para redirigir.
class IamStore extends ChangeNotifier {
  /// `this._repository` crea el parámetro con nombre `repository` (Dart 3.10+).
  IamStore({required this._repository, required this._storage}) {
    _storage.onSessionExpired = _expire;
  }

  final AuthRepository _repository;
  final SessionStorage _storage;

  AuthStatus _status = AuthStatus.unknown;
  UserSession? _session;

  AuthStatus get status => _status;
  UserSession? get session => _session;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Al abrir la app: si hay token guardado y sigue vigente, entra directo.
  Future<void> restoreSession() async {
    final token = await _storage.read();
    if (token == null) return _setUnauthenticated();
    try {
      _session = await _repository.restore(token);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on ApiError catch (error) {
      // Sin internet no cerramos la sesión: el token puede seguir siendo válido.
      if (error.isNetworkError) rethrow;
      await _storage.clear();
      _setUnauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final session = await _repository.signIn(email: email.trim(), password: password);
    await _storage.save(session.token);
    _session = session;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Paso 1 del onboarding: crea la cuenta y entra de una vez, para que el
  /// paso 2 (Profiles) ya tenga el token.
  Future<void> signUp({
    required String email,
    required String password,
    required AccountType accountType,
  }) async {
    await _repository.signUp(email: email.trim(), password: password, accountType: accountType);
    await signIn(email: email, password: password);
  }

  /// El backend responde 202 aunque el correo no exista (no revela qué cuentas hay).
  Future<void> requestPasswordRecovery(String email) =>
      _repository.requestPasswordRecovery(email.trim());

  Future<void> signOut() async {
    await _storage.clear();
    _setUnauthenticated();
  }

  void _expire() {
    if (_status != AuthStatus.authenticated) return;
    signOut();
  }

  void _setUnauthenticated() {
    _session = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
