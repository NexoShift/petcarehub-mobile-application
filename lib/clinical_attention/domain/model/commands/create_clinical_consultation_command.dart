import '../value_objects/clinical_field_limits.dart';
import 'command_validation.dart';

/// Abre una consulta (US01). El veterinario a cargo es el usuario autenticado.
class CreateClinicalConsultationCommand {
  CreateClinicalConsultationCommand({
    required int petId,
    required int clinicId,
    int? consultingRoomId,
    required String reason,
  }) : petId = CommandValidation.requireId(petId),
       clinicId = CommandValidation.requireId(clinicId),
       consultingRoomId = CommandValidation.optionalId(consultingRoomId),
       reason = CommandValidation.requireText(reason, ClinicalFieldLimits.reason);

  final int petId;
  final int clinicId;
  final int? consultingRoomId;
  final String reason;
}
