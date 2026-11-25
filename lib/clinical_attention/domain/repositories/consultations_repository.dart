import '../model/aggregates/clinical_consultation.dart';
import '../model/commands/add_clinical_finding_command.dart';
import '../model/commands/cancel_clinical_consultation_command.dart';
import '../model/commands/create_clinical_consultation_command.dart';
import '../model/commands/reevaluate_diagnosis_command.dart';
import '../model/commands/register_anamnesis_command.dart';
import '../model/commands/register_diagnosis_command.dart';
import '../model/commands/register_physiological_assessment_command.dart';

/// Puerto de consultas clínicas. Igual que la API, cada operación devuelve la
/// consulta completa. Los fallos se lanzan como ClinicalAttentionException.
abstract interface class ConsultationsRepository {
  /// Consultas de la mascota, de la más reciente a la más antigua.
  Future<List<ClinicalConsultation>> getByPet(int petId);

  Future<ClinicalConsultation> getById(int consultationId);

  Future<ClinicalConsultation> create(CreateClinicalConsultationCommand command);

  Future<ClinicalConsultation> start(int consultationId);

  Future<ClinicalConsultation> registerAnamnesis(RegisterAnamnesisCommand command);

  Future<ClinicalConsultation> registerPhysiologicalAssessment(
    RegisterPhysiologicalAssessmentCommand command,
  );

  Future<ClinicalConsultation> addClinicalFinding(AddClinicalFindingCommand command);

  Future<ClinicalConsultation> registerDiagnosis(RegisterDiagnosisCommand command);

  Future<ClinicalConsultation> reevaluateDiagnosis(ReevaluateDiagnosisCommand command);

  Future<ClinicalConsultation> complete(int consultationId);

  Future<ClinicalConsultation> cancel(CancelClinicalConsultationCommand command);
}
