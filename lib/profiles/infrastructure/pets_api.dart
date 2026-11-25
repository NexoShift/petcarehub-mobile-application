import '../../shared/domain/api_error.dart';
import '../../shared/domain/picked_image.dart';
import '../../shared/infrastructure/api_client.dart';
import '../domain/model/clinic.dart';
import '../domain/model/pet.dart';
import '../domain/model/pet_draft.dart';
import '../domain/repositories/pets_repository.dart';
import 'assemblers/profile_assemblers.dart';

/// Adaptador HTTP de mascotas y pacientes de clínica.
class PetsApi implements PetsRepository {
  PetsApi(this._client);

  final ApiClient _client;

  /// LocalDate del backend: 2026-09-12.
  static String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Map<String, String?> _fields(PetDraft draft) => {
        'name': draft.name,
        'species': draft.species.apiValue,
        'breed': draft.breed,
        'birthDate': draft.birthDate == null ? null : _localDate(draft.birthDate!),
        'sex': draft.sex?.apiValue,
      };

  @override
  Future<List<Pet>> getPetsByOwner(int petOwnerId) async => ProfileAssemblers.list(
        await _client.get('/pet-owners/$petOwnerId/pets'),
        ProfileAssemblers.pet,
      );

  @override
  Future<Pet> getPet(int petId) async =>
      ProfileAssemblers.pet(await _client.get('/pets/$petId'));

  @override
  Future<Pet> createPet({required int ownerId, required PetDraft draft, PickedImage? image}) async {
    final json = await _client.postMultipart(
      '/pets',
      {'ownerId': '$ownerId', ..._fields(draft)},
      files: {'image': ?image},
    );
    return ProfileAssemblers.pet(json as Map<String, dynamic>);
  }

  @override
  Future<Pet> updatePet({required int petId, required PetDraft draft}) async {
    final json = await _client.put('/pets/$petId', body: _fields(draft));
    return ProfileAssemblers.pet(json as Map<String, dynamic>);
  }

  @override
  Future<Pet> updatePetImage({required int petId, required PickedImage image}) async {
    final json = await _client.putMultipart('/pets/$petId/image', files: {'image': image});
    return ProfileAssemblers.pet(json as Map<String, dynamic>);
  }

  @override
  Future<List<Clinic>> getPetClinics(int petId) async => ProfileAssemblers.list(
        await _client.get('/pets/$petId/clinics'),
        ProfileAssemblers.clinic,
      );

  @override
  Future<List<Pet>> getClinicPatients(int clinicId) async => ProfileAssemblers.list(
        await _client.get('/clinics/$clinicId/patients'),
        ProfileAssemblers.pet,
      );

  @override
  Future<Pet?> findPetByCode(String petCode) async {
    try {
      return ProfileAssemblers.pet(
        await _client.get('/pets', query: {'petCode': petCode.trim().toUpperCase()}),
      );
    } on ApiError catch (error) {
      // 400 = formato de código inválido, 404 = no existe: para el usuario es lo mismo.
      if (error.isNotFound || error.status == 400) return null;
      rethrow;
    }
  }

  @override
  Future<void> registerClinicPatient({required int clinicId, required int petId}) async {
    await _client.post('/clinics/$clinicId/patients', body: {'petId': petId});
  }
}
