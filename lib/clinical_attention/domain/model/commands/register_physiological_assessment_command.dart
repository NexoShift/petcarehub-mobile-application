import '../clinical_attention_exception.dart';
import '../value_objects/clinical_field_limits.dart';
import '../value_objects/hydration_status.dart';
import '../value_objects/vital_signs.dart';
import 'command_validation.dart';

/// Una medición. Cada una se agrega a la consulta; ninguna se reemplaza.
class RegisterPhysiologicalAssessmentCommand {
  RegisterPhysiologicalAssessmentCommand({
    required int consultationId,
    required this.vitalSigns,
    this.bodyConditionScore,
    this.hydrationStatus,
    String? mucousMembranes,
    this.capillaryRefillTimeSeconds,
    String? observations,
  }) : consultationId = CommandValidation.requireId(consultationId),
       mucousMembranes = CommandValidation.optionalText(
         mucousMembranes,
         ClinicalFieldLimits.mucousMembranes,
       ),
       observations = CommandValidation.optionalText(
         observations,
         ClinicalFieldLimits.assessmentObservations,
       ) {
    final score = bodyConditionScore;
    final refill = capillaryRefillTimeSeconds;
    if ((score != null && !VitalSigns.isValidBodyConditionScore(score)) ||
        (refill != null && !VitalSigns.isValidCapillaryRefill(refill))) {
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidVitalSigns);
    }
  }

  final int consultationId;
  final VitalSigns vitalSigns;
  final int? bodyConditionScore;
  final HydrationStatus? hydrationStatus;
  final String? mucousMembranes;
  final double? capillaryRefillTimeSeconds;
  final String? observations;
}
