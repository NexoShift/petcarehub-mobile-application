import '../../shared/domain/api_error.dart';
import '../../shared/infrastructure/api_client.dart';
import '../domain/model/clinic.dart';
import '../domain/model/person_sex.dart';
import '../domain/model/pet_owner.dart';
import '../domain/repositories/profiles_repository.dart';

/// Adaptador HTTP de Profiles. Los POST son multipart porque el backend usa
/// @ModelAttribute (para aceptar la foto opcional).
class ProfilesApi implements ProfilesRepository {
  ProfilesApi(this._client);

  final ApiClient _client;

  @override
  Future<PetOwner?> findPetOwnerByUserId(int userId) async {
    try {
      final json = await _client.get('/pet-owners', query: {'userId': '$userId'});
      return PetOwner.fromJson(json as Map<String, dynamic>);
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

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
    return PetOwner.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Clinic?> findClinicByAccountId(int accountId) async {
    try {
      final json = await _client.get('/clinics', query: {'accountId': '$accountId'});
      return Clinic.fromJson(json as Map<String, dynamic>);
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

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
    return Clinic.fromJson(json as Map<String, dynamic>);
  }
}
