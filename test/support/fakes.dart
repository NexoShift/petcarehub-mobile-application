import 'dart:typed_data';

import 'package:petcare_mobile_application/clinical_attention/domain/model/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/consultation_summary.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/repositories/consultations_repository.dart';
import 'package:petcare_mobile_application/iam/domain/model/account_type.dart';
import 'package:petcare_mobile_application/iam/domain/model/user_session.dart';
import 'package:petcare_mobile_application/iam/domain/repositories/auth_repository.dart';
import 'package:petcare_mobile_application/profiles/domain/model/clinic.dart';
import 'package:petcare_mobile_application/profiles/domain/model/person_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_draft.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_owner.dart';
import 'package:petcare_mobile_application/profiles/domain/model/species.dart';
import 'package:petcare_mobile_application/profiles/domain/model/veterinarian.dart';
import 'package:petcare_mobile_application/profiles/domain/repositories/pets_repository.dart';
import 'package:petcare_mobile_application/profiles/domain/repositories/profiles_repository.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';
import 'package:petcare_mobile_application/shared/domain/picked_image.dart';
import 'package:petcare_mobile_application/shared/infrastructure/image_picker_service.dart';

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

UserSession clinicMemberSession({bool mustChangePassword = false}) => UserSession(
      userId: 3,
      accountId: 20,
      accountType: AccountType.clinic,
      email: 'vet@vetsur.pe',
      roles: const ['ROLE_VETERINARIAN'],
      mustChangePassword: mustChangePassword,
      token: 'jwt-vet',
    );

const roberto = PetOwner(
  id: 1,
  userId: 1,
  firstName: 'Roberto',
  lastName: 'García',
  email: 'roberto@example.com',
  phoneNumber: '+51987654321',
  sex: PersonSex.male,
);

const vetSur = Clinic(id: 5, accountId: 20, name: 'Clínica VetSur', address: 'Av. José Pardo 840');

const drMendoza = Veterinarian(
  id: 7,
  userId: 3,
  clinicId: 5,
  firstName: 'Francisco',
  lastName: 'Mendoza',
  email: 'vet@vetsur.pe',
  licenseNumber: '9841',
);

Pet pet({
  int id = 1,
  int ownerId = 1,
  String name = 'Max',
  Species species = Species.dog,
  String code = 'PET-ABCDEFGH',
}) =>
    Pet(
      id: id,
      ownerId: ownerId,
      petCode: code,
      name: name,
      species: species,
      breed: species == Species.dog ? 'Golden Retriever' : null,
      birthDate: DateTime(2023, 1, 15),
    );

PickedImage fakeImage({String mimeType = 'image/jpeg', int size = 10}) => PickedImage(
      bytes: Uint8List(size),
      fileName: 'foto.jpg',
      mimeType: mimeType,
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
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    _throwIfQueued();
    final entry = accounts.entries.firstWhere((e) => e.value.session.userId == userId);
    if (entry.value.password != currentPassword) {
      throw const ApiError(status: 400, message: 'Current password is incorrect');
    }
    accounts[entry.key] = (
      password: newPassword,
      session: entry.value.session.withPasswordChanged(),
    );
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
  final Map<int, Veterinarian> vetsByUserId = {};
  PersonSex? lastSex;
  ApiError? nextError;
  int imageUploads = 0;

  void _throwIfQueued() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

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
    _throwIfQueued();
    lastSex = sex;
    return petOwnersByUserId[userId] = PetOwner(
      id: petOwnersByUserId.length + 1,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      sex: sex,
    );
  }

  @override
  Future<PetOwner> updatePetOwner({
    required int petOwnerId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  }) async {
    _throwIfQueued();
    final current = petOwnersByUserId.values.firstWhere((o) => o.id == petOwnerId);
    return petOwnersByUserId[current.userId] = PetOwner(
      id: current.id,
      userId: current.userId,
      firstName: firstName,
      lastName: lastName,
      email: current.email,
      phoneNumber: phoneNumber,
      sex: sex,
      profileImageUrl: current.profileImageUrl,
    );
  }

  @override
  Future<PetOwner> updatePetOwnerImage({required int petOwnerId, required PickedImage image}) async {
    _throwIfQueued();
    imageUploads++;
    return petOwnersByUserId.values.firstWhere((o) => o.id == petOwnerId);
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
  }) async =>
      clinicsByAccountId[accountId] = Clinic(id: 1, accountId: accountId, name: name);

  @override
  Future<Clinic> getClinic(int clinicId) async =>
      clinicsByAccountId.values.firstWhere((c) => c.id == clinicId);

  @override
  Future<Veterinarian?> findVeterinarianByUserId(int userId) async => vetsByUserId[userId];
}

/// Mascotas y pacientes en memoria.
class FakePetsRepository implements PetsRepository {
  final Map<int, Pet> pets = {};
  final Map<int, List<int>> patientsByClinic = {};
  final Map<int, List<Clinic>> clinicsByPet = {};
  final List<({int petId, bool withImage})> created = [];
  ApiError? nextError;
  int _nextId = 50;

  void _throwIfQueued() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  void add(Pet value) => pets[value.id] = value;

  @override
  Future<List<Pet>> getPetsByOwner(int petOwnerId) async {
    _throwIfQueued();
    return pets.values.where((p) => p.ownerId == petOwnerId).toList();
  }

  @override
  Future<Pet> getPet(int petId) async {
    _throwIfQueued();
    final value = pets[petId];
    if (value == null) throw const ApiError(status: 404, message: 'Pet not found');
    return value;
  }

  @override
  Future<Pet> createPet({required int ownerId, required PetDraft draft, PickedImage? image}) async {
    _throwIfQueued();
    final id = _nextId++;
    created.add((petId: id, withImage: image != null));
    return pets[id] = Pet(
      id: id,
      ownerId: ownerId,
      petCode: 'PET-NEW${id}XYZ'.substring(0, 12),
      name: draft.name,
      species: draft.species,
      breed: draft.breed,
      birthDate: draft.birthDate,
      sex: draft.sex,
    );
  }

  @override
  Future<Pet> updatePet({required int petId, required PetDraft draft}) async {
    _throwIfQueued();
    final current = pets[petId]!;
    return pets[petId] = Pet(
      id: petId,
      ownerId: current.ownerId,
      petCode: current.petCode,
      name: draft.name,
      species: draft.species,
      breed: draft.breed,
      birthDate: draft.birthDate,
      sex: draft.sex,
    );
  }

  @override
  Future<Pet> updatePetImage({required int petId, required PickedImage image}) async => pets[petId]!;

  @override
  Future<List<Clinic>> getPetClinics(int petId) async => clinicsByPet[petId] ?? const [];

  @override
  Future<List<Pet>> getClinicPatients(int clinicId) async {
    _throwIfQueued();
    return [for (final id in patientsByClinic[clinicId] ?? const <int>[]) pets[id]!];
  }

  @override
  Future<Pet?> findPetByCode(String petCode) async =>
      pets.values.where((p) => p.petCode == petCode).firstOrNull;

  @override
  Future<void> registerClinicPatient({required int clinicId, required int petId}) async {
    _throwIfQueued();
    final list = patientsByClinic.putIfAbsent(clinicId, () => []);
    if (list.contains(petId)) throw const ApiError(status: 409, message: 'Already a patient');
    list.add(petId);
  }
}

class FakeConsultationsRepository implements ConsultationsRepository {
  final Map<int, List<ConsultationSummary>> byPet = {};
  int calls = 0;

  @override
  Future<List<ConsultationSummary>> getByPet(int petId) async {
    calls++;
    return byPet[petId] ?? const [];
  }
}

ConsultationSummary consultation({
  int id = 1,
  int petId = 1,
  String reason = 'Pododermatitis',
  ConsultationStatus status = ConsultationStatus.completed,
  DateTime? date,
  String? diagnosis,
}) =>
    ConsultationSummary(
      id: id,
      petId: petId,
      clinicId: 5,
      reason: reason,
      status: status,
      createdAt: date ?? DateTime(2026, 9, 12),
      completedAt: date ?? DateTime(2026, 9, 12),
      mainDiagnosis: diagnosis,
    );

class FakeImagePicker implements ImagePickerService {
  PickedImage? next;

  @override
  Future<PickedImage?> pick(ImageSourceOption source) async => next;
}
