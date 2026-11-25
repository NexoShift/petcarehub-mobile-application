import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/pending_item.dart';

import '../../support/fakes.dart';

void main() {
  test('recién creada: se puede iniciar o cancelar, pero no registrar datos', () {
    final c = consultation(status: ConsultationStatus.created);
    expect(c.canStart, isTrue);
    expect(c.canCancel, isTrue);
    expect(c.isClosed, isFalse);
    expect(c.canRegisterAnamnesis, isFalse);
    expect(c.canRegisterPrimaryDiagnosis, isFalse);
    expect(c.canComplete, isFalse);
  });

  test('en curso sin datos: informa todo lo pendiente', () {
    final c = consultation(status: ConsultationStatus.inProgress);
    expect(c.canRegisterAnamnesis, isTrue);
    expect(c.pendingItems, PendingItem.values);
    expect(c.canComplete, isFalse);
  });

  test('en curso con anamnesis, evaluación y diagnóstico principal: se puede finalizar', () {
    final c = consultation(
      status: ConsultationStatus.inProgress,
      anamnesis: anamnesis(),
      assessments: [assessment()],
      diagnoses: [diagnosis()],
    );
    expect(c.pendingItems, isEmpty);
    expect(c.canComplete, isTrue);
    expect(c.canRegisterAnamnesis, isFalse);
    expect(c.canRegisterPrimaryDiagnosis, isFalse);
  });

  test('un diagnóstico secundario no basta para finalizar', () {
    final c = consultation(
      status: ConsultationStatus.inProgress,
      anamnesis: anamnesis(),
      assessments: [assessment()],
      diagnoses: [diagnosis(primary: false)],
    );
    expect(c.pendingItems, [PendingItem.primaryDiagnosis]);
    expect(c.mainDiagnosis, 'Pododermatitis alérgica');
  });

  test('el diagnóstico reemplazado no es el principal, pero se conserva (CON-01)', () {
    final c = consultation(
      diagnoses: [
        diagnosis(id: 1, description: 'Sarna', status: DiagnosisStatus.superseded),
        diagnosis(id: 2, description: 'Pododermatitis', previousDiagnosisId: 1),
      ],
    );
    expect(c.primaryDiagnosis!.id, 2);
    expect(c.mainDiagnosis, 'Pododermatitis');
    expect(c.supersededDiagnoses.single.description, 'Sarna');
    expect(c.diagnoses, hasLength(2));
  });

  test('la última medición es la más reciente y la lista conserva todas', () {
    final c = consultation(
      assessments: [assessment(id: 1, weightKg: 28), assessment(id: 2, weightKg: 28.5)],
    );
    expect(c.latestAssessment!.vitalSigns.weightKg, 28.5);
    expect(c.physiologicalAssessments, hasLength(2));
  });

  test('finalizada o cancelada: registro cerrado', () {
    for (final status in [ConsultationStatus.completed, ConsultationStatus.cancelled]) {
      final c = consultation(status: status);
      expect(c.isClosed, isTrue);
      expect(c.canCancel, isFalse);
      expect(c.canComplete, isFalse);
    }
  });
}
