import 'package:petcare_mobile_application/iam/domain/model/account_type.dart';
import 'package:petcare_mobile_application/iam/domain/model/user_session.dart';
import 'package:petcare_mobile_application/iam/domain/repositories/auth_repository.dart';
import 'package:petcare_mobile_application/profiles/domain/model/clinic.dart';
import 'package:petcare_mobile_application/profiles/domain/model/person_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_owner.dart';
import 'package:petcare_mobile_application/profiles/domain/repositories/profiles_repository.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';

UserSession ownerSession({int userId = 1, String token = 'jwt-owner'}) => UserSession(
  userId: userId,
  accountId: 10,
  accountType: AccountType.petOwner,
  email: 'roberto@example.com',
  roles: const ['ROLE_PET_OWNER'],
  mustChangePassword: false,
  token: token,
);

UserSession clinicAdminSession() => const UserSession(
  userId: 2,
  accountId: 20,
  accountType: AccountType.clinic,
  email: 'admin@vetsur.pe',
  roles: ['ROLE_CLINIC_ADMIN', 'ROLE_VETERINARIAN'],
  mustChangePassword: false,
  token: 'jwt-clinic',
);

UserSession clinicMemberSession() => const UserSession(
  userId: 3,
  accountId: 20,
  accountType: AccountType.clinic,
  email: 'vet@vetsur.pe',
  roles: ['ROLE_VETERINARIAN'],
  mustChangePassword: false,
  token: 'jwt-vet',
);

/// IAM en memoria: cuentas registradas por correo.
class FakeAuthRepository implements AuthRepository {
  final Map<String, ({String password, UserSession session})> accounts = {};
  final List<String> recoveryRequests = [];
  ApiError? nextError;
  int _nextUserId = 100;

  void addAccount(String password, UserSession session) =>
      accounts[session.email] = (password: password, session: session);

  void _throwIfQueued() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required AccountType accountType,
  }) async {
    _throwIfQueued();
    if (accounts.containsKey(email)) {
      throw const ApiError(status: 409, message: 'Email already registered');
    }
    final id = _nextUserId++;
    addAccount(
      password,
      UserSession(
        userId: id,
        accountId: id,
        accountType: accountType,
        email: email,
        roles: accountType == AccountType.petOwner
            ? const ['ROLE_PET_OWNER']
            : const ['ROLE_CLINIC_ADMIN', 'ROLE_VETERINARIAN'],
        mustChangePassword: false,
        token: 'jwt-$id',
      ),
    );
  }

  @override
  Future<UserSession> signIn({required String email, required String password}) async {
    _throwIfQueued();
    final account = accounts[email];
    if (account == null || account.password != password) {
      throw const ApiError(status: 401, message: 'Invalid credentials');
    }
    return account.session;
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    _throwIfQueued();
    recoveryRequests.add(email);
  }

  @override
  Future<UserSession> restore(String token) async {
    _throwIfQueued();
    for (final account in accounts.values) {
      if (account.session.token == token) return account.session;
    }
    throw const ApiError(status: 401, message: 'Invalid token');
  }
}

/// Profiles en memoria.
class FakeProfilesRepository implements ProfilesRepository {
  final Map<int, PetOwner> petOwnersByUserId = {};
  final Map<int, Clinic> clinicsByAccountId = {};
  PersonSex? lastSex;
  ApiError? nextError;

  @override
  Future<PetOwner?> findPetOwnerByUserId(int userId) async => petOwnersByUserId[userId];

  @override
  Future<PetOwner> createPetOwner({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    lastSex = sex;
    return petOwnersByUserId[userId] = PetOwner(
      id: petOwnersByUserId.length + 1,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<Clinic?> findClinicByAccountId(int accountId) async => clinicsByAccountId[accountId];

  @override
  Future<Clinic> createClinic({
    required int accountId,
    required String name,
    String? ruc,
    String? address,
    String? phoneNumber,
  }) async => clinicsByAccountId[accountId] = Clinic(id: 1, accountId: accountId, name: name);
}
