import '../../shared/domain/api_error.dart';
import '../../shared/infrastructure/api_client.dart';
import '../domain/model/aggregates/clinical_consultation.dart';
import '../domain/model/clinical_attention_exception.dart';
import '../domain/model/commands/add_clinical_finding_command.dart';
import '../domain/model/commands/cancel_clinical_consultation_command.dart';
import '../domain/model/commands/create_clinical_consultation_command.dart';
import '../domain/model/commands/reevaluate_diagnosis_command.dart';
import '../domain/model/commands/register_anamnesis_command.dart';
import '../domain/model/commands/register_diagnosis_command.dart';
import '../domain/model/commands/register_physiological_assessment_command.dart';
import '../domain/repositories/consultations_repository.dart';
import 'assemblers/clinical_consultation_assembler.dart';
import 'assemblers/clinical_error_assembler.dart';
import 'assemblers/clinical_request_assembler.dart';

/// Adaptador HTTP de /clinical-consultations y /pets/{petId}/clinical-consultations.
class ConsultationsApi implements ConsultationsRepository {
  ConsultationsApi(this._client);

  final ApiClient _client;

  static const _path = '/clinical-consultations';

  @override
  Future<List<ClinicalConsultation>> getByPet(int petId) => _guard(
    () async => ClinicalConsultationAssembler.fromJsonList(
      await _client.get('/pets/$petId/clinical-consultations'),
    ),
    notFound: ClinicalAttentionErrorCode.petNotFound,
  );

  @override
  Future<ClinicalConsultation> getById(int consultationId) =>
      _read(() => _client.get('$_path/$consultationId'));

  @override
  Future<ClinicalConsultation> create(CreateClinicalConsultationCommand command) => _read(
    () => _client.post(_path, body: ClinicalRequestAssembler.create(command)),
    notFound: ClinicalAttentionErrorCode.petNotFound,
  );

  @override
  Future<ClinicalConsultation> start(int consultationId) =>
      _read(() => _client.put('$_path/$consultationId/start'));

  @override
  Future<ClinicalConsultation> registerAnamnesis(RegisterAnamnesisCommand command) => _read(
    () => _client.post(
      '$_path/${command.consultationId}/anamnesis',
      body: ClinicalRequestAssembler.anamnesis(command),
    ),
  );

  @override
  Future<ClinicalConsultation> registerPhysiologicalAssessment(
    RegisterPhysiologicalAssessmentCommand command,
  ) => _read(
    () => _client.post(
      '$_path/${command.consultationId}/physiological-assessments',
      body: ClinicalRequestAssembler.assessment(command),
    ),
  );

  @override
  Future<ClinicalConsultation> addClinicalFinding(AddClinicalFindingCommand command) => _read(
    () => _client.post(
      '$_path/${command.consultationId}/findings',
      body: ClinicalRequestAssembler.finding(command),
    ),
  );

  @override
  Future<ClinicalConsultation> registerDiagnosis(RegisterDiagnosisCommand command) => _read(
    () => _client.post(
      '$_path/${command.consultationId}/diagnoses',
      body: ClinicalRequestAssembler.diagnosis(command),
    ),
    conflict: ClinicalAttentionErrorCode.diagnosisConflict,
  );

  @override
  Future<ClinicalConsultation> reevaluateDiagnosis(ReevaluateDiagnosisCommand command) => _read(
    () => _client.post(
      '$_path/${command.consultationId}/diagnoses/${command.diagnosisId}/reevaluations',
      body: ClinicalRequestAssembler.reevaluation(command),
    ),
    conflict: ClinicalAttentionErrorCode.diagnosisConflict,
  );

  @override
  Future<ClinicalConsultation> complete(int consultationId) => _read(
    () => _client.put('$_path/$consultationId/complete'),
    conflict: ClinicalAttentionErrorCode.incompleteConsultation,
  );

  @override
  Future<ClinicalConsultation> cancel(CancelClinicalConsultationCommand command) => _read(
    () => _client.put(
      '$_path/${command.consultationId}/cancel',
      body: ClinicalRequestAssembler.cancellation(command),
    ),
  );

  Future<ClinicalConsultation> _read(
    Future<dynamic> Function() request, {
    ClinicalAttentionErrorCode notFound = ClinicalAttentionErrorCode.consultationNotFound,
    ClinicalAttentionErrorCode conflict = ClinicalAttentionErrorCode.invalidConsultationState,
  }) => _guard(
    () async => ClinicalConsultationAssembler.fromJson(await request() as Map<String, dynamic>),
    notFound: notFound,
    conflict: conflict,
  );

  Future<T> _guard<T>(
    Future<T> Function() action, {
    ClinicalAttentionErrorCode notFound = ClinicalAttentionErrorCode.consultationNotFound,
    ClinicalAttentionErrorCode conflict = ClinicalAttentionErrorCode.invalidConsultationState,
  }) async {
    try {
      return await action();
    } on ApiError catch (error) {
      throw ClinicalErrorAssembler.fromApiError(error, notFound: notFound, conflict: conflict);
    } on TypeError {
      // La API respondió 2xx con un cuerpo que no es una consulta.
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.unexpected);
    }
  }
}
