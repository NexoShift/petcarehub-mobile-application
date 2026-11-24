import '../../shared/domain/api_error.dart';

/// Traduce los errores de la API a mensajes para el usuario en las pantallas de acceso.
class AuthErrorMessages {
  const AuthErrorMessages._();

  static String signIn(Object error) {
    if (error is! ApiError) return _unexpected;
    if (error.isNetworkError) return error.message;
    if (error.isUnauthorized) return 'Correo o contraseña incorrectos.';
    if (error.isForbidden) return 'Tu cuenta está desactivada. Comunícate con tu clínica.';
    return _unexpected;
  }

  static String signUp(Object error) {
    if (error is! ApiError) return _unexpected;
    if (error.isNetworkError) return error.message;
    if (error.isConflict) return 'Ya existe una cuenta con ese correo.';
    if (error.status == 400) return 'Revisa los datos: ${error.message}';
    return _unexpected;
  }

  static const _unexpected = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
