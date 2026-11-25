import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/application/consultations_store.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/infrastructure/consultations_api.dart';

import '../support/fakes.dart';

void main() {
  test('el assembler toma el diagnóstico principal', () {
    final summary = ConsultationSummaryAssembler.fromJson({
      'id': 4,
      'petId': 1,
      'clinicId': 5,
      'reason': 'Lamido de pata',
      'status': 'COMPLETED',
      'createdAt': '2026-09-12T15:00:00Z',
      'completedAt': '2026-09-12T15:45:00Z',
      'diagnoses': [
        {'description': 'Presuntivo', 'primary': false},
        {'description': 'Pododermatitis alérgica', 'primary': true},
      ],
    });
    expect(summary.status, ConsultationStatus.completed);
    expect(summary.mainDiagnosis, 'Pododermatitis alérgica');
    expect(summary.date, DateTime.utc(2026, 9, 12, 15, 45));
  });

  test('sin diagnósticos ni fecha de cierre', () {
    final summary = ConsultationSummaryAssembler.fromJson({
      'id': 4,
      'petId': 1,
      'clinicId': 5,
      'reason': 'Control',
      'status': 'IN_PROGRESS',
      'createdAt': '2026-09-12T15:00:00Z',
      'diagnoses': [],
    });
    expect(summary.mainDiagnosis, isNull);
    expect(summary.date, DateTime.utc(2026, 9, 12, 15));
  });

  test('el store ordena de la más reciente a la más antigua y usa caché', () async {
    final repository = FakeConsultationsRepository()
      ..byPet[1] = [
        consultation(id: 1, date: DateTime(2026, 2, 2)),
        consultation(id: 2, date: DateTime(2026, 9, 12)),
      ];
    final store = ConsultationsStore(repository: repository);

    await store.loadForPet(1);
    await store.loadForPet(1);

    expect(store.consultationsOf(1)!.map((c) => c.id), [2, 1]);
    expect(repository.calls, 1);

    await store.loadForPet(1, force: true);
    expect(repository.calls, 2);
  });
}
