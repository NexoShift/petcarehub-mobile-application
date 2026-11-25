import '../../shared/domain/api_error.dart';
import '../../shared/domain/picked_image.dart';
import '../../shared/infrastructure/api_client.dart';
import '../domain/model/clinic.dart';
import '../domain/model/person_sex.dart';
import '../domain/model/pet_owner.dart';
import '../domain/model/veterinarian.dart';
import '../domain/repositories/profiles_repository.dart';
import 'assemblers/profile_assemblers.dart';

/// Adaptador HTTP de los perfiles. Los POST son multipart porque el backend usa
/// @ModelAttribute (para aceptar la foto opcional).
class ProfilesApi implements ProfilesRepository {
  ProfilesApi(this._client);

  final ApiClient _client;

  /// Convierte un 404 en null (el recurso aún no existe).
  Future<T?> _orNull<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<PetOwner?> findPetOwnerByUserId(int userId) => _orNull(() async =>
      ProfileAssemblers.petOwner(await _client.get('/pet-owners', query: {'userId': '$userId'})));

  @override
  Future<PetOwner> createPetOwner({
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  }) async {
    final json = await _client.postMultipart('/pet-owners', {
      'userId': '$userId',
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'sex': sex?.apiValue,
    });
    return ProfileAssemblers.petOwner(json as Map<String, dynamic>);
  }

  @override
  Future<PetOwner> updatePetOwner({
    required int petOwnerId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  }) async {
    final json = await _client.put('/pet-owners/$petOwnerId', body: {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'sex': sex?.apiValue,
    });
    return ProfileAssemblers.petOwner(json as Map<String, dynamic>);
  }

  @override
  Future<PetOwner> updatePetOwnerImage({required int petOwnerId, required PickedImage image}) async {
    final json = await _client.putMultipart(
      '/pet-owners/$petOwnerId/profile-image',
      files: {'image': image},
    );
    return ProfileAssemblers.petOwner(json as Map<String, dynamic>);
  }

  @override
  Future<Clinic?> findClinicByAccountId(int accountId) => _orNull(() async =>
      ProfileAssemblers.clinic(await _client.get('/clinics', query: {'accountId': '$accountId'})));

  @override
  Future<Clinic> createClinic({
    required int accountId,
    required String name,
    String? ruc,
    String? address,
    String? phoneNumber,
  }) async {
    final json = await _client.postMultipart('/clinics', {
      'accountId': '$accountId',
      'name': name,
      'ruc': ruc,
      'address': address,
      'phoneNumber': phoneNumber,
    });
    return ProfileAssemblers.clinic(json as Map<String, dynamic>);
  }

  @override
  Future<Clinic> getClinic(int clinicId) async =>
      ProfileAssemblers.clinic(await _client.get('/clinics/$clinicId'));

  @override
  Future<Veterinarian?> findVeterinarianByUserId(int userId) => _orNull(() async =>
      ProfileAssemblers.veterinarian(
        await _client.get('/veterinarians', query: {'userId': '$userId'}),
      ));
}
