import '../../shared/infrastructure/api_client.dart';
import '../domain/model/account_type.dart';
import '../domain/model/user_session.dart';
import '../domain/repositories/auth_repository.dart';

/// Adaptador HTTP de IAM: /authentication/* y /users/me.
class AuthApi implements AuthRepository {
  AuthApi(this._client);

  final ApiClient _client;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required AccountType accountType,
  }) async {
    await _client.post(
      '/authentication/sign-up',
      body: {'email': email, 'password': password, 'accountType': accountType.apiValue},
    );
  }

  @override
  Future<UserSession> signIn({required String email, required String password}) async {
    final json = await _client.post(
      '/authentication/sign-in',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    return UserSessionAssembler.fromAuthenticatedUser(json);
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    await _client.post('/authentication/password-recovery', body: {'email': email});
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put('/users/$userId/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  @override
  Future<UserSession> restore(String token) async {
    final json = await _client.get('/users/me') as Map<String, dynamic>;
    return UserSessionAssembler.fromUser(json, token);
  }
}

/// Convierte los recursos JSON del backend en el modelo de dominio.
class UserSessionAssembler {
  const UserSessionAssembler._();

  /// AuthenticatedUserResource(userId, accountId, accountType, email, roles, mustChangePassword, token)
  static UserSession fromAuthenticatedUser(Map<String, dynamic> json) => UserSession(
    userId: (json['userId'] as num).toInt(),
    accountId: (json['accountId'] as num).toInt(),
    accountType: AccountType.fromApi(json['accountType'] as String),
    email: json['email'] as String,
    roles: List<String>.from(json['roles'] as List),
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    token: json['token'] as String,
  );

  /// UserResource(id, accountId, accountType, email, accessRole, status, roles, mustChangePassword)
  static UserSession fromUser(Map<String, dynamic> json, String token) => UserSession(
    userId: (json['id'] as num).toInt(),
    accountId: (json['accountId'] as num).toInt(),
    accountType: AccountType.fromApi(json['accountType'] as String),
    email: json['email'] as String,
    roles: List<String>.from(json['roles'] as List),
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    token: token,
  );
}
