import 'account_type.dart';

/// Sesión del usuario autenticado (lo que devuelve POST /authentication/sign-in).
class UserSession {
  const UserSession({
    required this.userId,
    required this.accountId,
    required this.accountType,
    required this.email,
    required this.roles,
    required this.mustChangePassword,
    required this.token,
  });

  final int userId;
  final int accountId;
  final AccountType accountType;
  final String email;
  final List<String> roles;
  final bool mustChangePassword;
  final String token;

  /// Copia con la contraseña temporal ya cambiada.
  UserSession withPasswordChanged() => UserSession(
        userId: userId,
        accountId: accountId,
        accountType: accountType,
        email: email,
        roles: roles,
        mustChangePassword: false,
        token: token,
      );

  bool hasRole(String role) => roles.contains(role);

  bool get isPetOwner => hasRole('ROLE_PET_OWNER');
  bool get isClinicAdmin => hasRole('ROLE_CLINIC_ADMIN');
  bool get isVeterinarian => hasRole('ROLE_VETERINARIAN');

  /// Vet agregado por el admin de la clínica (no es titular de la cuenta).
  bool get isClinicMember => accountType == AccountType.clinic && !isClinicAdmin;
}
