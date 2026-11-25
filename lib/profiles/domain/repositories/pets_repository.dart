import '../../../shared/domain/picked_image.dart';
import '../model/clinic.dart';
import '../model/pet.dart';
import '../model/pet_draft.dart';

/// Puerto de mascotas y pacientes.
abstract interface class PetsRepository {
  Future<List<Pet>> getPetsByOwner(int petOwnerId);

  Future<Pet> getPet(int petId);

  /// POST /pets (multipart): datos + foto opcional.
  Future<Pet> createPet({required int ownerId, required PetDraft draft, PickedImage? image});

  Future<Pet> updatePet({required int petId, required PetDraft draft});

  Future<Pet> updatePetImage({required int petId, required PickedImage image});

  /// Clínicas donde la mascota está registrada como paciente.
  Future<List<Clinic>> getPetClinics(int petId);

  /// Pacientes de una clínica (para el vet).
  Future<List<Pet>> getClinicPatients(int clinicId);

  /// Busca una mascota por su código (ej. PET-98102). null si no existe.
  Future<Pet?> findPetByCode(String petCode);

  /// Registra una mascota existente como paciente de la clínica.
  Future<void> registerClinicPatient({required int clinicId, required int petId});
}
