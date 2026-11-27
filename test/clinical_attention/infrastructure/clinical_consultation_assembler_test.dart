import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/body_system.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_type.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/finding_severity.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/hydration_status.dart';
import 'package:petcare_mobile_application/clinical_attention/infrastructure/assemblers/clinical_consultation_assembler.dart';

void main() {
  test('convierte el recurso completo', () {
    final c = ClinicalConsultationAssembler.fromJson({
      'id': 4,
      'petId': 1,
      'veterinarianId': 7,
      'clinicId': 5,
      'consultingRoomId': 3,
      'reason': 'Lamido de pata',
      'status': 'COMPLETED',
      'createdAt': '2026-09-12T15:00:00Z',
      'startedAt': '2026-09-12T15:05:00Z',
      'completedAt': '2026-09-12T15:45:00Z',
      'anamnesis': {
        'id': 1,
        'chiefComplaint': 'Lamido',
        'evolutionTime': '3 días',
        'symptoms': ['Eritema'],
        'diet': null,
      },
      'physiologicalAssessments': [
        {
          'id': 2,
          'weightKg': 28.5,
          'temperatureCelsius': 38,
          'heartRateBpm': 115,
          'respiratoryRateBpm': 24,
          'bodyConditionScore': 5,
          'hydrationStatus': 'MILD_DEHYDRATION',
          'capillaryRefillTimeSeconds': 2,
          'recordedAt': '2026-09-12T15:10:00Z',
        },
      ],
      'findings': [
        {
          'id': 3,
          'bodySystem': 'INTEGUMENTARY',
          'description': 'Eritema',
          'severity': 'MODERATE',
          'recordedAt': '2026-09-12T15:12:00Z',
        },
      ],
      'diagnoses': [
        {
          'id': 4,
          'description': 'Sarna',
          'type': 'PRESUMPTIVE',
          'primary': true,
          'status': 'SUPERSEDED',
          'diagnosedAt': '2026-09-12T15:20:00Z',
        },
        {
          'id': 5,
          'description': 'Pododermatitis alérgica',
          'type': 'DEFINITIVE',
          'primary': true,
          'status': 'CURRENT',
          'differentialDiagnoses': ['Sarna'],
          'previousDiagnosisId': 4,
          'diagnosedAt': '2026-09-12T15:30:00Z',
        },
      ],
    });

    expect(c.status, ConsultationStatus.completed);
    expect(c.consultingRoomId, 3);
    expect(c.date, DateTime.utc(2026, 9, 12, 15, 45));
    expect(c.anamnesis!.symptoms, ['Eritema']);
    final assessment = c.latestAssessment!;
    expect(assessment.vitalSigns.temperatureCelsius, 38.0);
    expect(assessment.hydrationStatus, HydrationStatus.mildDehydration);
    expect(assessment.capillaryRefillTimeSeconds, 2.0);
    expect(c.findings.single.bodySystem, BodySystem.integumentary);
    expect(c.findings.single.severity, FindingSeverity.moderate);
    // El principal vigente, no el primero marcado como principal.
    expect(c.mainDiagnosis, 'Pododermatitis alérgica');
    expect(c.primaryDiagnosis!.type, DiagnosisType.definitive);
    expect(c.primaryDiagnosis!.previousDiagnosisId, 4);
  });

  test('tolera lo que la API aún no tiene (listas null, sin cierre)', () {
    final c = ClinicalConsultationAssembler.fromJson({
      'id': 4,
      'petId': 1,
      'clinicId': 5,
      'reason': 'Control',
      'status': 'IN_PROGRESS',
      'createdAt': '2026-09-12T15:00:00Z',
      'physiologicalAssessments': null,
      'diagnoses': <dynamic>[],
    });
    expect(c.mainDiagnosis, isNull);
    expect(c.anamnesis, isNull);
    expect(c.physiologicalAssessments, isEmpty);
    expect(c.date, DateTime.utc(2026, 9, 12, 15));
  });
}
