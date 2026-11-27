import '../../domain/model/commands/add_clinical_finding_command.dart';
import '../../domain/model/commands/cancel_clinical_consultation_command.dart';
import '../../domain/model/commands/create_clinical_consultation_command.dart';
import '../../domain/model/commands/diagnosis_content.dart';
import '../../domain/model/commands/reevaluate_diagnosis_command.dart';
import '../../domain/model/commands/register_anamnesis_command.dart';
import '../../domain/model/commands/register_diagnosis_command.dart';
import '../../domain/model/commands/register_physiological_assessment_command.dart';

/// Convierte los commands en el cuerpo JSON que espera la API.
abstract final class ClinicalRequestAssembler {
  static Map<String, Object?> create(CreateClinicalConsultationCommand command) => {
    'petId': command.petId,
    'clinicId': command.clinicId,
    'consultingRoomId': command.consultingRoomId,
    'reason': command.reason,
  };

  static Map<String, Object?> anamnesis(RegisterAnamnesisCommand command) => {
    'chiefComplaint': command.chiefComplaint,
    'evolutionTime': command.evolutionTime,
    'symptoms': command.symptoms,
    'diet': command.diet,
    'behavior': command.behavior,
    'previousTreatments': command.previousTreatments,
    'ownerObservations': command.ownerObservations,
  };

  static Map<String, Object?> assessment(RegisterPhysiologicalAssessmentCommand command) => {
    'weightKg': command.vitalSigns.weightKg,
    'temperatureCelsius': command.vitalSigns.temperatureCelsius,
    'heartRateBpm': command.vitalSigns.heartRateBpm,
    'respiratoryRateBpm': command.vitalSigns.respiratoryRateBpm,
    'bodyConditionScore': command.bodyConditionScore,
    'hydrationStatus': command.hydrationStatus?.apiValue,
    'mucousMembranes': command.mucousMembranes,
    'capillaryRefillTimeSeconds': command.capillaryRefillTimeSeconds,
    'observations': command.observations,
  };

  static Map<String, Object?> finding(AddClinicalFindingCommand command) => {
    'bodySystem': command.bodySystem.apiValue,
    'description': command.description,
    'severity': command.severity?.apiValue,
  };

  static Map<String, Object?> diagnosis(RegisterDiagnosisCommand command) => {
    ..._content(command.content),
    'primary': command.primary,
  };

  static Map<String, Object?> reevaluation(ReevaluateDiagnosisCommand command) =>
      _content(command.content);

  static Map<String, Object?> cancellation(CancelClinicalConsultationCommand command) => {
    'reason': command.reason,
  };

  static Map<String, Object?> _content(DiagnosisContent content) => {
    'description': content.description,
    'type': content.type.apiValue,
    'differentialDiagnoses': content.differentialDiagnoses,
    'rationale': content.rationale,
  };
}
