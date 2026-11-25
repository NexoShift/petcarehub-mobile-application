import '../../../shared/domain/picked_image.dart';
import '../model/clinic.dart';
import '../model/person_sex.dart';
import '../model/pet_owner.dart';
import '../model/veterinarian.dart';

/// Puerto de los perfiles de personas y clínicas.
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

  Future<PetOwner> updatePetOwner({
    required int petOwnerId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  });

  Future<PetOwner> updatePetOwnerImage({required int petOwnerId, required PickedImage image});

  Future<Clinic?> findClinicByAccountId(int accountId);

  Future<Clinic> createClinic({
    required int accountId,
    required String name,
    String? ruc,
    String? address,
    String? phoneNumber,
  });

  Future<Clinic> getClinic(int clinicId);

  /// null si la clínica aún no registró el perfil del vet.
  Future<Veterinarian?> findVeterinarianByUserId(int userId);
}
