import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/application/consultations_store.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/aggregates/clinical_consultation.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';

import '../../support/fakes.dart';

class _SlowRepository extends FakeConsultationsRepository {
  final completer = Completer<List<ClinicalConsultation>>();

  @override
  Future<List<ClinicalConsultation>> getByPet(int petId) => completer.future;
}

void main() {
  test('ordena de la más reciente a la más antigua y usa caché', () async {
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

  test('guarda el error de la mascota y se limpia al reintentar', () async {
    final repository = FakeConsultationsRepository()
      ..nextError = const ClinicalAttentionException(ClinicalAttentionErrorCode.noConnection);
    final store = ConsultationsStore(repository: repository);

    await store.loadForPet(1);
    expect(store.errorOf(1), ClinicalAttentionErrorCode.noConnection);

    await store.loadForPet(1);
    expect(store.errorOf(1), isNull);
    expect(store.consultationsOf(1), isEmpty);
  });

  test('upsert agrega o reemplaza solo si la lista ya se cargó', () async {
    final repository = FakeConsultationsRepository()
      ..byPet[1] = [consultation(id: 1, status: ConsultationStatus.inProgress)];
    final store = ConsultationsStore(repository: repository)..upsert(consultation(id: 9, petId: 2));
    expect(store.consultationsOf(2), isNull);

    await store.loadForPet(1);
    store
      ..upsert(consultation(id: 1, status: ConsultationStatus.completed))
      ..upsert(consultation(id: 2, date: DateTime(2026, 10, 1)));
    expect(store.consultationsOf(1)!.map((c) => c.id), [2, 1]);
    expect(store.find(petId: 1, consultationId: 1)!.status, ConsultationStatus.completed);
  });

  test('una respuesta que llega después de cerrar sesión se descarta', () async {
    final repository = _SlowRepository();
    final store = ConsultationsStore(repository: repository);
    final loading = store.loadForPet(1);
    store.clear();
    repository.completer.complete([consultation()]);
    await loading;
    expect(store.consultationsOf(1), isNull);
  });
}
