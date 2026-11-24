import '../model/account_type.dart';
import '../model/user_session.dart';

/// Puerto de IAM. La implementación HTTP vive en infrastructure (AuthApi),
/// y en los tests se reemplaza por un fake.
abstract interface class AuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    required AccountType accountType,
  });

  Future<UserSession> signIn({required String email, required String password});

  /// Pide el correo de recuperación. El enlace abre la web (reset-password).
  Future<void> requestPasswordRecovery(String email);

  /// Valida un token guardado con GET /users/me y devuelve la sesión actualizada.
  Future<UserSession> restore(String token);
}
