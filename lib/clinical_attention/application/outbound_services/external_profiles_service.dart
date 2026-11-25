import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/attending_staff.dart';
import '../../domain/model/value_objects/consulting_room_snapshot.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';

/// Puerto hacia el bounded context Profiles (Anti-Corruption Layer).
///
/// Es el equivalente al ExternalProfilesService del backend: Clinical Attention
/// pide mascotas, nombres y consultorios sin conocer los modelos de Profiles.
abstract interface class ExternalProfilesService {
  Future<PatientSnapshot> getPatient(int petId);

  Future<List<PatientSnapshot>> getClinicPatients(int clinicId);

  /// Lista vacía si la clínica no tiene consultorios o no se pueden leer.
  Future<List<ConsultingRoomSnapshot>> getActiveConsultingRooms(int clinicId);

  /// Nombres del veterinario, la clínica, el tutor y el consultorio. Nunca falla:
  /// lo que no se puede leer queda en null.
  Future<AttendingStaff> getAttendingStaff(ClinicalConsultation consultation, {int? ownerId});
}
