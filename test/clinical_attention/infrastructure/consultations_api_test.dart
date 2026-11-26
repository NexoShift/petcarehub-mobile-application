import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/add_clinical_finding_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/cancel_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/create_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/diagnosis_content.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/reevaluate_diagnosis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_anamnesis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_diagnosis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_physiological_assessment_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/body_system.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_type.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/finding_severity.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/hydration_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/pending_item.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/vital_signs.dart';
import 'package:petcare_mobile_application/clinical_attention/infrastructure/consultations_api.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';

const consultationJson = {
  'id': 8,
  'petId': 1,
  'veterinarianId': 7,
  'clinicId': 5,
  'reason': 'Tos',
  'status': 'IN_PROGRESS',
  'createdAt': '2026-09-12T15:00:00Z',
};

void main() {
  late http.Request sent;

  ConsultationsApi api({int status = 200, Object? body = consultationJson}) => ConsultationsApi(
    ApiClient(
      baseUrl: 'http://api.test/api/v1',
      tokenProvider: InMemorySessionStorage(),
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
      }),
    ),
  );

  void expectSent(String method, String path, [Object? body]) {
    expect(sent.method, method);
    expect(sent.url.path, '/api/v1$path');
    if (body != null) expect(jsonDecode(sent.body), body);
  }

  final content = DiagnosisContent(
    description: 'Pododermatitis',
    type: DiagnosisType.presumptive,
    differentialDiagnoses: ['Sarna'],
  );

  test('lista las consultas de una mascota', () async {
    final list = await api(body: [consultationJson]).getByPet(1);
    expectSent('GET', '/pets/1/clinical-consultations');
    expect(list.single.id, 8);
  });

  test('obtiene, inicia y finaliza', () async {
    await api().getById(8);
    expectSent('GET', '/clinical-consultations/8');
    await api().start(8);
    expectSent('PUT', '/clinical-consultations/8/start');
    await api().complete(8);
    expectSent('PUT', '/clinical-consultations/8/complete');
  });

  test('crea con el cuerpo del contrato', () async {
    final created = await api(status: 201).create(
      CreateClinicalConsultationCommand(petId: 1, clinicId: 5, consultingRoomId: 3, reason: 'Tos'),
    );
    expectSent('POST', '/clinical-consultations', {
      'petId': 1,
      'clinicId': 5,
      'consultingRoomId': 3,
      'reason': 'Tos',
    });
    expect(created.id, 8);
  });

  test('registra la anamnesis', () async {
    await api(status: 201).registerAnamnesis(
      RegisterAnamnesisCommand(
        consultationId: 8,
        chiefComplaint: 'Tos',
        evolutionTime: '2 días',
        symptoms: ['Fiebre'],
      ),
    );
    expectSent('POST', '/clinical-consultations/8/anamnesis', {
      'chiefComplaint': 'Tos',
      'evolutionTime': '2 días',
      'symptoms': ['Fiebre'],
      'diet': null,
      'behavior': null,
      'previousTreatments': null,
      'ownerObservations': null,
    });
  });

  test('registra la evaluación fisiológica', () async {
    await api(status: 201).registerPhysiologicalAssessment(
      RegisterPhysiologicalAssessmentCommand(
        consultationId: 8,
        vitalSigns: VitalSigns.measured(
          weightKg: 28.5,
          temperatureCelsius: 38.6,
          heartRateBpm: 115,
          respiratoryRateBpm: 24,
        ),
        bodyConditionScore: 5,
        hydrationStatus: HydrationStatus.normal,
      ),
    );
    expectSent('POST', '/clinical-consultations/8/physiological-assessments', {
      'weightKg': 28.5,
      'temperatureCelsius': 38.6,
      'heartRateBpm': 115,
      'respiratoryRateBpm': 24,
      'bodyConditionScore': 5,
      'hydrationStatus': 'NORMAL',
      'mucousMembranes': null,
      'capillaryRefillTimeSeconds': null,
      'observations': null,
    });
  });

  test('agrega un hallazgo', () async {
    await api(status: 201).addClinicalFinding(
      AddClinicalFindingCommand(
        consultationId: 8,
        bodySystem: BodySystem.otic,
        description: 'Otitis',
        severity: FindingSeverity.mild,
      ),
    );
    expectSent('POST', '/clinical-consultations/8/findings', {
      'bodySystem': 'OTIC',
      'description': 'Otitis',
      'severity': 'MILD',
    });
  });

  test('registra y reevalúa diagnósticos', () async {
    await api(status: 201).registerDiagnosis(
      RegisterDiagnosisCommand(consultationId: 8, content: content, primary: true),
    );
    expectSent('POST', '/clinical-consultations/8/diagnoses', {
      'description': 'Pododermatitis',
      'type': 'PRESUMPTIVE',
      'differentialDiagnoses': ['Sarna'],
      'rationale': null,
      'primary': true,
    });

    await api(status: 201).reevaluateDiagnosis(
      ReevaluateDiagnosisCommand(consultationId: 8, diagnosisId: 2, content: content),
    );
    expectSent('POST', '/clinical-consultations/8/diagnoses/2/reevaluations', {
      'description': 'Pododermatitis',
      'type': 'PRESUMPTIVE',
      'differentialDiagnoses': ['Sarna'],
      'rationale': null,
    });
  });

  test('cancela con motivo', () async {
    await api().cancel(CancelClinicalConsultationCommand(consultationId: 8, reason: 'No asistió'));
    expectSent('PUT', '/clinical-consultations/8/cancel', {'reason': 'No asistió'});
  });

  group('errores', () {
    Matcher throwsCode(ClinicalAttentionErrorCode code) =>
        throwsA(isA<ClinicalAttentionException>().having((e) => e.code, 'code', code));

    test('409 al completar trae lo pendiente', () async {
      final failing = api(
        status: 409,
        body: {
          'message': 'Incomplete',
          'details': ['anamnesis', 'primaryDiagnosis'],
        },
      );
      await expectLater(
        failing.complete(8),
        throwsA(
          isA<ClinicalAttentionException>()
              .having((e) => e.code, 'code', ClinicalAttentionErrorCode.incompleteConsultation)
              .having((e) => e.pendingItems, 'pendientes', [
                PendingItem.anamnesis,
                PendingItem.primaryDiagnosis,
              ]),
        ),
      );
    });

    test('409 al completar sin detalle: la consulta cambió de estado', () async {
      await expectLater(
        api(status: 409, body: {'message': 'x'}).complete(8),
        throwsCode(ClinicalAttentionErrorCode.invalidConsultationState),
      );
    });

    test('409 de diagnóstico', () async {
      await expectLater(
        api(status: 409, body: {'message': 'x'}).registerDiagnosis(
          RegisterDiagnosisCommand(consultationId: 8, content: content, primary: true),
        ),
        throwsCode(ClinicalAttentionErrorCode.diagnosisConflict),
      );
    });

    test('404 depende de la operación', () async {
      final missing = api(status: 404, body: {'message': 'x'});
      await expectLater(
        missing.getById(8),
        throwsCode(ClinicalAttentionErrorCode.consultationNotFound),
      );
      await expectLater(
        missing.create(CreateClinicalConsultationCommand(petId: 9, clinicId: 5, reason: 'Tos')),
        throwsCode(ClinicalAttentionErrorCode.petNotFound),
      );
      await expectLater(missing.getByPet(9), throwsCode(ClinicalAttentionErrorCode.petNotFound));
    });

    test('422 al crear: la mascota no es paciente de la clínica', () async {
      await expectLater(
        api(status: 422, body: {'message': 'x'}).create(
          CreateClinicalConsultationCommand(petId: 9, clinicId: 5, reason: 'Tos'),
        ),
        throwsCode(ClinicalAttentionErrorCode.petNotPatient),
      );
    });

    test('400, 401, 403 y 500', () async {
      for (final (status, code) in [
        (400, ClinicalAttentionErrorCode.invalidRequest),
        (401, ClinicalAttentionErrorCode.sessionExpired),
        (403, ClinicalAttentionErrorCode.notAllowed),
        (500, ClinicalAttentionErrorCode.unexpected),
      ]) {
        await expectLater(api(status: status, body: {'message': 'x'}).getById(8), throwsCode(code));
      }
    });

    test('sin conexión', () async {
      final offline = ConsultationsApi(
        ApiClient(
          baseUrl: 'http://api.test/api/v1',
          tokenProvider: InMemorySessionStorage(),
          httpClient: MockClient((_) => throw http.ClientException('sin red')),
        ),
      );
      await expectLater(offline.start(8), throwsCode(ClinicalAttentionErrorCode.noConnection));
    });

    test('respuesta 200 que no es una consulta', () async {
      await expectLater(
        api(body: {'otra': 'cosa'}).getById(8),
        throwsCode(ClinicalAttentionErrorCode.unexpected),
      );
      await expectLater(
        api(body: null).getById(8),
        throwsCode(ClinicalAttentionErrorCode.unexpected),
      );
    });
  });
}
