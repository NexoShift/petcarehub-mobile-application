import 'package:petcare_mobile_application/clinical_attention/application/outbound_services/external_profiles_service.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/aggregates/clinical_consultation.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/add_clinical_finding_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/cancel_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/create_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/reevaluate_diagnosis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_anamnesis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_diagnosis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_physiological_assessment_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/entities/anamnesis.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/entities/clinical_finding.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/entities/diagnosis.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/entities/physiological_assessment.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/attending_staff.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consulting_room_snapshot.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_type.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/patient_snapshot.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/vital_signs.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/repositories/consultations_repository.dart';

final fixedNow = DateTime(2026, 9, 12, 10, 45);

const maxPatient = PatientSnapshot(
  petId: 1,
  ownerId: 1,
  code: 'PET-ABCDEFGH',
  name: 'Max',
  species: 'Canino',
  breed: 'Golden Retriever',
);

const lunaPatient = PatientSnapshot(
  petId: 2,
  ownerId: 1,
  code: 'PET-LUNALUNA',
  name: 'Luna',
  species: 'Felino',
);

Anamnesis anamnesis() => const Anamnesis(
  id: 1,
  chiefComplaint: 'Lamido de pata',
  evolutionTime: '3 a 5 días',
  symptoms: ['Eritema visible'],
);

PhysiologicalAssessment assessment({int id = 1, double weightKg = 28.5}) => PhysiologicalAssessment(
  id: id,
  vitalSigns: VitalSigns(
    weightKg: weightKg,
    temperatureCelsius: 38.6,
    heartRateBpm: 115,
    respiratoryRateBpm: 24,
  ),
  recordedAt: fixedNow,
);

Diagnosis diagnosis({
  int id = 1,
  String description = 'Pododermatitis alérgica',
  bool primary = true,
  DiagnosisStatus status = DiagnosisStatus.current,
  int? previousDiagnosisId,
}) => Diagnosis(
  id: id,
  description: description,
  type: DiagnosisType.definitive,
  primary: primary,
  status: status,
  diagnosedAt: fixedNow,
  previousDiagnosisId: previousDiagnosisId,
);

ClinicalConsultation consultation({
  int id = 1,
  int petId = 1,
  String reason = 'Pododermatitis',
  ConsultationStatus status = ConsultationStatus.completed,
  DateTime? date,
  Anamnesis? anamnesis,
  List<PhysiologicalAssessment> assessments = const [],
  List<ClinicalFinding> findings = const [],
  List<Diagnosis> diagnoses = const [],
  String? cancellationReason,
}) => ClinicalConsultation(
  id: id,
  petId: petId,
  veterinarianId: 7,
  clinicId: 5,
  reason: reason,
  status: status,
  createdAt: date ?? fixedNow,
  startedAt: status == ConsultationStatus.created ? null : date ?? fixedNow,
  completedAt: status == ConsultationStatus.completed ? date ?? fixedNow : null,
  cancelledAt: status == ConsultationStatus.cancelled ? date ?? fixedNow : null,
  cancellationReason: cancellationReason,
  anamnesis: anamnesis,
  physiologicalAssessments: assessments,
  findings: findings,
  diagnoses: diagnoses,
);

/// Consultas en memoria, con las mismas reglas de estado del backend.
class FakeConsultationsRepository implements ConsultationsRepository {
  final Map<int, List<ClinicalConsultation>> byPet = {};
  int calls = 0;
  int writes = 0;
  ClinicalAttentionException? nextError;
  CreateClinicalConsultationCommand? lastCreate;
  RegisterAnamnesisCommand? lastAnamnesis;
  RegisterPhysiologicalAssessmentCommand? lastAssessment;
  int _nextId = 100;

  void add(ClinicalConsultation value) => byPet.putIfAbsent(value.petId, () => []).add(value);

  void _throwIfQueued() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<List<ClinicalConsultation>> getByPet(int petId) async {
    calls++;
    _throwIfQueued();
    return byPet[petId] ?? const [];
  }

  @override
  Future<ClinicalConsultation> getById(int consultationId) async {
    _throwIfQueued();
    return _find(consultationId);
  }

  @override
  Future<ClinicalConsultation> create(CreateClinicalConsultationCommand command) async {
    _throwIfQueued();
    writes++;
    lastCreate = command;
    final created = consultation(
      id: _nextId++,
      petId: command.petId,
      reason: command.reason,
      status: ConsultationStatus.created,
    );
    add(created);
    return created;
  }

  @override
  Future<ClinicalConsultation> start(int consultationId) => _update(
    consultationId,
    (c) => _copy(c, status: ConsultationStatus.inProgress),
    required: ConsultationStatus.created,
  );

  @override
  Future<ClinicalConsultation> registerAnamnesis(RegisterAnamnesisCommand command) {
    lastAnamnesis = command;
    return _update(
      command.consultationId,
      (c) => _copy(
        c,
        anamnesis: Anamnesis(
          id: _nextId++,
          chiefComplaint: command.chiefComplaint,
          evolutionTime: command.evolutionTime,
          symptoms: command.symptoms,
          previousTreatments: command.previousTreatments,
        ),
      ),
    );
  }

  @override
  Future<ClinicalConsultation> registerPhysiologicalAssessment(
    RegisterPhysiologicalAssessmentCommand command,
  ) {
    lastAssessment = command;
    return _update(
      command.consultationId,
      (c) => _copy(
        c,
        assessments: [
          ...c.physiologicalAssessments,
          PhysiologicalAssessment(
            id: _nextId++,
            vitalSigns: command.vitalSigns,
            recordedAt: fixedNow,
          ),
        ],
      ),
    );
  }

  @override
  Future<ClinicalConsultation> addClinicalFinding(AddClinicalFindingCommand command) => _update(
    command.consultationId,
    (c) => _copy(
      c,
      findings: [
        ...c.findings,
        ClinicalFinding(
          id: _nextId++,
          bodySystem: command.bodySystem,
          description: command.description,
          severity: command.severity,
          recordedAt: fixedNow,
        ),
      ],
    ),
  );

  @override
  Future<ClinicalConsultation> registerDiagnosis(RegisterDiagnosisCommand command) => _update(
    command.consultationId,
    (c) => _copy(
      c,
      diagnoses: [
        ...c.diagnoses,
        Diagnosis(
          id: _nextId++,
          description: command.content.description,
          type: command.content.type,
          primary: command.primary,
          status: DiagnosisStatus.current,
          diagnosedAt: fixedNow,
        ),
      ],
    ),
  );

  @override
  Future<ClinicalConsultation> reevaluateDiagnosis(ReevaluateDiagnosisCommand command) =>
      _update(command.consultationId, (c) {
        final previous = c.diagnoses.firstWhere((d) => d.id == command.diagnosisId);
        return _copy(
          c,
          diagnoses: [
            for (final d in c.diagnoses)
              if (d.id == previous.id)
                Diagnosis(
                  id: d.id,
                  description: d.description,
                  type: d.type,
                  primary: d.primary,
                  status: DiagnosisStatus.superseded,
                  diagnosedAt: d.diagnosedAt,
                )
              else
                d,
            Diagnosis(
              id: _nextId++,
              description: command.content.description,
              type: command.content.type,
              primary: previous.primary,
              status: DiagnosisStatus.current,
              diagnosedAt: fixedNow,
              previousDiagnosisId: previous.id,
            ),
          ],
        );
      });

  @override
  Future<ClinicalConsultation> complete(int consultationId) => _update(consultationId, (c) {
    if (c.pendingItems.isNotEmpty) {
      throw ClinicalAttentionException(
        ClinicalAttentionErrorCode.incompleteConsultation,
        pendingItems: c.pendingItems,
      );
    }
    return _copy(c, status: ConsultationStatus.completed, completedAt: fixedNow);
  });

  @override
  Future<ClinicalConsultation> cancel(CancelClinicalConsultationCommand command) async {
    _throwIfQueued();
    final current = _find(command.consultationId);
    return _replace(
      _copy(
        current,
        status: ConsultationStatus.cancelled,
        cancelledAt: fixedNow,
        cancellationReason: command.reason,
      ),
    );
  }

  ClinicalConsultation _find(int id) {
    for (final list in byPet.values) {
      for (final c in list) {
        if (c.id == id) return c;
      }
    }
    throw const ClinicalAttentionException(ClinicalAttentionErrorCode.consultationNotFound);
  }

  Future<ClinicalConsultation> _update(
    int id,
    ClinicalConsultation Function(ClinicalConsultation) change, {
    ConsultationStatus required = ConsultationStatus.inProgress,
  }) async {
    _throwIfQueued();
    final current = _find(id);
    if (current.status != required) {
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidConsultationState);
    }
    return _replace(change(current));
  }

  ClinicalConsultation _replace(ClinicalConsultation value) {
    writes++;
    final list = byPet[value.petId]!;
    list[list.indexWhere((c) => c.id == value.id)] = value;
    return value;
  }

  static ClinicalConsultation _copy(
    ClinicalConsultation c, {
    ConsultationStatus? status,
    Anamnesis? anamnesis,
    List<PhysiologicalAssessment>? assessments,
    List<ClinicalFinding>? findings,
    List<Diagnosis>? diagnoses,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) => ClinicalConsultation(
    id: c.id,
    petId: c.petId,
    veterinarianId: c.veterinarianId,
    clinicId: c.clinicId,
    reason: c.reason,
    status: status ?? c.status,
    createdAt: c.createdAt,
    startedAt: c.startedAt ?? fixedNow,
    completedAt: completedAt ?? c.completedAt,
    cancelledAt: cancelledAt ?? c.cancelledAt,
    cancellationReason: cancellationReason ?? c.cancellationReason,
    anamnesis: anamnesis ?? c.anamnesis,
    physiologicalAssessments: assessments ?? c.physiologicalAssessments,
    findings: findings ?? c.findings,
    diagnoses: diagnoses ?? c.diagnoses,
  );
}

/// ACL de Profiles en memoria.
class FakeExternalProfilesService implements ExternalProfilesService {
  List<PatientSnapshot> patients = [lunaPatient, maxPatient];
  List<ConsultingRoomSnapshot> rooms = const [ConsultingRoomSnapshot(id: 3, name: 'Consultorio 1')];
  AttendingStaff staff = const AttendingStaff(
    veterinarianName: 'Francisco Mendoza',
    licenseNumber: '9841',
    clinicName: 'Clínica VetSur',
    ownerName: 'Roberto García',
  );
  ClinicalAttentionException? nextError;
  int staffCalls = 0;

  @override
  Future<PatientSnapshot> getPatient(int petId) async =>
      patients.where((p) => p.petId == petId).firstOrNull ??
      (throw const ClinicalAttentionException(ClinicalAttentionErrorCode.petNotFound));

  @override
  Future<List<PatientSnapshot>> getClinicPatients(int clinicId) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return patients;
  }

  @override
  Future<List<ConsultingRoomSnapshot>> getActiveConsultingRooms(int clinicId) async => rooms;

  @override
  Future<AttendingStaff> getAttendingStaff(
    ClinicalConsultation consultation, {
    int? ownerId,
  }) async {
    staffCalls++;
    return staff;
  }
}
