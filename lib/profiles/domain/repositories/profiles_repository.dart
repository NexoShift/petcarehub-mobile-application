import '../model/clinic.dart';
import '../model/person_sex.dart';
import '../model/pet_owner.dart';

abstract interface class ProfilesRepository {
  /// null si el usuario aún no completó su perfil (la API responde 404).
  Future<PetOwner?> findPetOwnerByUserId(int userId);

  Future<PetOwner> createPetOwner({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  });

  Future<Clinic?> findClinicByAccountId(int accountId);

  Future<Clinic> createClinic({
    required int accountId,
    required String name,
    String? ruc,
    String? address,
    String? phoneNumber,
  });
}
