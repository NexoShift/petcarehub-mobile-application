import '../../../profiles/domain/model/pet.dart';
import '../../../profiles/domain/repositories/pets_repository.dart';
import '../../../profiles/domain/repositories/profiles_repository.dart';
import '../../../shared/domain/api_error.dart';
import '../../../shared/infrastructure/api_client.dart';
import '../../application/outbound_services/external_profiles_service.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/clinical_attention_exception.dart';
import '../../domain/model/value_objects/attending_staff.dart';
import '../../domain/model/value_objects/consulting_room_snapshot.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import '../assemblers/clinical_error_assembler.dart';

/// Anti-Corruption Layer: el único archivo de Clinical Attention que conoce a Profiles.
///
/// Usa los puertos de Profiles cuando existen. Veterinario por id, tutor por id
/// y consultorios aún no están en el Profiles móvil, así que se leen de su API.
class ProfilesAclService implements ExternalProfilesService {
  ProfilesAclService({required this._pets, required this._profiles, required this._client});

  final PetsRepository _pets;
  final ProfilesRepository _profiles;
  final ApiClient _client;

  @override
  Future<PatientSnapshot> getPatient(int petId) =>
      _guard(() async => _toSnapshot(await _pets.getPet(petId)));

  @override
  Future<List<PatientSnapshot>> getClinicPatients(int clinicId) => _guard(() async {
    final patients = [for (final pet in await _pets.getClinicPatients(clinicId)) _toSnapshot(pet)];
    return patients..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  });

  @override
  Future<List<ConsultingRoomSnapshot>> getActiveConsultingRooms(int clinicId) async {
    final json = await _optional(() => _client.get('/clinics/$clinicId/consulting-rooms'));
    return [
      for (final room in json is List ? json : const [])
        if (room is Map<String, dynamic> && room['active'] == true)
          ConsultingRoomSnapshot(
            id: (room['id'] as num).toInt(),
            name: room['name'] as String? ?? '',
          ),
    ];
  }

  @override
  Future<AttendingStaff> getAttendingStaff(
    ClinicalConsultation consultation, {
    int? ownerId,
  }) async {
    final roomId = consultation.consultingRoomId;
    final (veterinarian, clinic, owner, room) = await (
      _optionalJson('/veterinarians/${consultation.veterinarianId}'),
      _optional(() => _profiles.getClinic(consultation.clinicId)),
      ownerId == null ? Future.value(null) : _optionalJson('/pet-owners/$ownerId'),
      roomId == null
          ? Future.value(null)
          : _optionalJson('/clinics/${consultation.clinicId}/consulting-rooms/$roomId'),
    ).wait;
    return AttendingStaff(
      veterinarianName: _fullName(veterinarian),
      licenseNumber: veterinarian?['licenseNumber'] as String?,
      clinicName: clinic?.name,
      ownerName: _fullName(owner),
      consultingRoomName: room?['name'] as String?,
    );
  }

  static PatientSnapshot _toSnapshot(Pet pet) => PatientSnapshot(
    petId: pet.id,
    ownerId: pet.ownerId,
    code: pet.petCode,
    name: pet.name,
    species: pet.species.label,
    breed: pet.breed,
    birthDate: pet.birthDate,
    photoUrl: pet.profileImageUrl,
  );

  static String? _fullName(Map<String, dynamic>? json) {
    final name = '${json?['firstName'] ?? ''} ${json?['lastName'] ?? ''}'.trim();
    return name.isEmpty ? null : name;
  }

  Future<Map<String, dynamic>?> _optionalJson(String path) async {
    final json = await _optional(() => _client.get(path));
    return json is Map<String, dynamic> ? json : null;
  }

  /// Datos de apoyo: si Profiles no los entrega, la consulta se muestra sin ellos.
  Future<T?> _optional<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiError {
      return null;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiError catch (error) {
      throw ClinicalErrorAssembler.fromApiError(
        error,
        notFound: ClinicalAttentionErrorCode.petNotFound,
      );
    }
  }
}
