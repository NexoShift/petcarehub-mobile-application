import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/application/consultation_workspace_store.dart';
import 'package:petcare_mobile_application/clinical_attention/application/consultations_store.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/aggregates/clinical_consultation.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/cancel_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/commands/create_clinical_consultation_command.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/pending_item.dart';

import '../../support/fakes.dart';

class _SlowStartRepository extends FakeConsultationsRepository {
  final completer = Completer<void>();

  @override
  Future<ClinicalConsultation> start(int consultationId) async {
    await completer.future;
    return super.start(consultationId);
  }
}

void main() {
  late FakeConsultationsRepository repository;
  late ConsultationsStore consultations;
  late ConsultationWorkspaceStore store;

  void build(FakeConsultationsRepository repo) {
    repository = repo;
    consultations = ConsultationsStore(repository: repository);
    store = ConsultationWorkspaceStore(repository: repository, consultations: consultations);
  }

  setUp(() => build(FakeConsultationsRepository()));

  test('crear e iniciar actualiza también la lista de la mascota', () async {
    await consultations.loadForPet(1);
    final created = await store.create(
      CreateClinicalConsultationCommand(petId: 1, clinicId: 5, reason: 'Tos'),
    );
    expect(created, isTrue);
    final id = store.consultation!.id;
    expect(consultations.consultationsOf(1)!.single.status, ConsultationStatus.created);

    expect(await store.start(id), isTrue);
    expect(store.consultation!.isInProgress, isTrue);
    expect(consultations.consultationsOf(1)!.single.isInProgress, isTrue);
  });

  test('un error no cambia la consulta y se limpia al volver a intentar', () async {
    repository
      ..add(consultation(status: ConsultationStatus.created))
      ..nextError = null;
    await store.load(1);
    repository.nextError = const ClinicalAttentionException(ClinicalAttentionErrorCode.notAllowed);

    expect(await store.start(1), isFalse);
    expect(store.error, ClinicalAttentionErrorCode.notAllowed);
    expect(store.consultation!.canStart, isTrue);

    expect(await store.start(1), isTrue);
    expect(store.error, isNull);
  });

  test('finalizar incompleta informa lo pendiente', () async {
    repository.add(consultation(status: ConsultationStatus.inProgress, anamnesis: anamnesis()));
    await store.load(1);
    expect(await store.complete(1), isFalse);
    expect(store.error, ClinicalAttentionErrorCode.incompleteConsultation);
    expect(store.pendingItems, [PendingItem.physiologicalAssessment, PendingItem.primaryDiagnosis]);
  });

  test('cancelar guarda el motivo', () async {
    repository.add(consultation(status: ConsultationStatus.created));
    await store.load(1);
    await store.cancel(CancelClinicalConsultationCommand(consultationId: 1, reason: 'No asistió'));
    expect(store.consultation!.cancellationReason, 'No asistió');
    expect(store.consultation!.isClosed, isTrue);
  });

  test('consulta que no existe', () async {
    expect(await store.load(99), isFalse);
    expect(store.error, ClinicalAttentionErrorCode.consultationNotFound);
    expect(store.isLoading, isFalse);
  });

  test('un doble toque no registra dos veces', () async {
    final slow = _SlowStartRepository()..add(consultation(status: ConsultationStatus.created));
    build(slow);
    await store.load(1);
    final first = store.start(1);
    expect(store.isSaving, isTrue);
    expect(await store.start(1), isFalse);
    expect(
      await store.create(CreateClinicalConsultationCommand(petId: 1, clinicId: 5, reason: 'x')),
      isFalse,
    );
    slow.completer.complete();
    expect(await first, isTrue);
    expect(slow.writes, 1);
    expect(store.isSaving, isFalse);
  });

  test('una respuesta que llega después de cerrar sesión se descarta', () async {
    final slow = _SlowStartRepository()..add(consultation(status: ConsultationStatus.created));
    build(slow);
    await store.load(1);
    final pending = store.start(1);
    store.clear();
    slow.completer.complete();
    expect(await pending, isFalse);
    expect(store.consultation, isNull);
    expect(store.isSaving, isFalse);
  });
}
