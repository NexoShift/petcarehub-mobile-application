import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/add_clinical_finding_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/cancel_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/create_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/diagnosis_content.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_anamnesis_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/register_physiological_assessment_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/body_system.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_type.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/vital_signs.dart';

Matcher throwsCode(ClinicalAttentionErrorCode code) =>
    throwsA(isA<ClinicalAttentionException>().having((e) => e.code, 'code', code));

final throwsInvalid = throwsCode(ClinicalAttentionErrorCode.invalidRequest);
final throwsVitals = throwsCode(ClinicalAttentionErrorCode.invalidVitalSigns);

VitalSigns vitals({double weight = 28.5, double temp = 38.6, int heart = 115, int resp = 24}) =>
    VitalSigns.measured(
      weightKg: weight,
      temperatureCelsius: temp,
      heartRateBpm: heart,
      respiratoryRateBpm: resp,
    );

void main() {
  group('crear consulta', () {
    test('recorta el motivo', () {
      final command = CreateClinicalConsultationCommand(petId: 1, clinicId: 5, reason: '  Tos  ');
      expect(command.reason, 'Tos');
      expect(command.consultingRoomId, isNull);
    });

    test('rechaza ids inválidos y motivos vacíos o largos', () {
      CreateClinicalConsultationCommand create({int pet = 1, int? room, String reason = 'Tos'}) =>
          CreateClinicalConsultationCommand(
            petId: pet,
            clinicId: 5,
            consultingRoomId: room,
            reason: reason,
          );
      expect(() => create(pet: 0), throwsInvalid);
      expect(() => create(room: -1), throwsInvalid);
      expect(() => create(reason: '   '), throwsInvalid);
      expect(create(reason: 'a' * 350).reason, hasLength(350));
      expect(() => create(reason: 'a' * 351), throwsInvalid);
    });
  });

  group('anamnesis', () {
    RegisterAnamnesisCommand register({
      String complaint = 'Lamido',
      String evolution = '3 días',
      List<String> symptoms = const [],
      String? diet,
    }) => RegisterAnamnesisCommand(
      consultationId: 1,
      chiefComplaint: complaint,
      evolutionTime: evolution,
      symptoms: symptoms,
      diet: diet,
    );

    test('limpia síntomas repetidos y vacíos, y los opcionales en blanco quedan en null', () {
      final command = register(symptoms: [' Tos ', 'tos', '', 'Fiebre'], diet: '  ');
      expect(command.symptoms, ['Tos', 'Fiebre']);
      expect(command.diet, isNull);
    });

    test('valida obligatorios y límites', () {
      expect(() => register(complaint: ''), throwsInvalid);
      expect(() => register(evolution: ' '), throwsInvalid);
      expect(() => register(evolution: 'a' * 101), throwsInvalid);
      expect(() => register(diet: 'a' * 501), throwsInvalid);
      expect(() => register(symptoms: ['a' * 101]), throwsInvalid);
      expect(register(symptoms: [for (var i = 0; i < 20; i++) 's$i']).symptoms, hasLength(20));
      expect(() => register(symptoms: [for (var i = 0; i < 21; i++) 's$i']), throwsInvalid);
    });
  });

  group('evaluación fisiológica', () {
    test('acepta los extremos de cada rango', () {
      expect(vitals(weight: 500, temp: 30, heart: 1, resp: 1).weightKg, 500);
      expect(vitals(temp: 45, heart: 600, resp: 300).heartRateBpm, 600);
    });

    test('rechaza constantes fuera de rango', () {
      expect(() => vitals(weight: 0), throwsVitals);
      expect(() => vitals(weight: 500.1), throwsVitals);
      expect(() => vitals(temp: 29.9), throwsVitals);
      expect(() => vitals(temp: 45.1), throwsVitals);
      expect(() => vitals(heart: 0), throwsVitals);
      expect(() => vitals(heart: 601), throwsVitals);
      expect(() => vitals(resp: 301), throwsVitals);
      expect(() => vitals(weight: double.nan), throwsVitals);
    });

    test('valida condición corporal, llenado capilar y textos', () {
      RegisterPhysiologicalAssessmentCommand register({
        int? score,
        double? refill,
        String? mucous,
      }) => RegisterPhysiologicalAssessmentCommand(
        consultationId: 1,
        vitalSigns: vitals(),
        bodyConditionScore: score,
        capillaryRefillTimeSeconds: refill,
        mucousMembranes: mucous,
      );
      expect(register(score: 9, refill: 0.5).bodyConditionScore, 9);
      expect(register().bodyConditionScore, isNull);
      expect(() => register(score: 0), throwsVitals);
      expect(() => register(score: 10), throwsVitals);
      expect(() => register(refill: 0), throwsVitals);
      expect(() => register(mucous: 'a' * 101), throwsInvalid);
    });
  });

  test('hallazgo: descripción obligatoria', () {
    expect(
      () => AddClinicalFindingCommand(
        consultationId: 1,
        bodySystem: BodySystem.otic,
        description: ' ',
      ),
      throwsInvalid,
    );
  });

  test('diagnóstico: limpia diferenciales y respeta el máximo de 10', () {
    DiagnosisContent content(List<String> differentials) => DiagnosisContent(
      description: 'Pododermatitis',
      type: DiagnosisType.definitive,
      differentialDiagnoses: differentials,
    );
    expect(content([' Sarna ', 'sarna']).differentialDiagnoses, ['Sarna']);
    expect(() => content([for (var i = 0; i < 11; i++) 'd$i']), throwsInvalid);
    expect(() => content(['a' * 201]), throwsInvalid);
  });

  test('cancelación: el motivo es obligatorio y tiene su propio error', () {
    CancelClinicalConsultationCommand cancel(String reason) =>
        CancelClinicalConsultationCommand(consultationId: 1, reason: reason);
    expect(cancel(' No asistió ').reason, 'No asistió');
    expect(() => cancel(' '), throwsCode(ClinicalAttentionErrorCode.invalidCancellation));
    expect(() => cancel('a' * 501), throwsCode(ClinicalAttentionErrorCode.invalidCancellation));
  });
}
