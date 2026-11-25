import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petcare_mobile_application/app/dependencies.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/entities/anamnesis.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/consultation_status.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/diagnosis_status.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';

import '../../support/fakes.dart';

/// Flujos de Clinical Attention de punta a punta, con repositorios falsos (sin red).
void main() {
  late FakeAuthRepository auth;
  late FakeProfilesRepository profiles;
  late FakePetsRepository pets;
  late FakeConsultationsRepository consultations;
  late FakeExternalProfilesService external;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('Secreta123', ownerSession())
      ..addAccount('Secreta123', clinicMemberSession());
    profiles = FakeProfilesRepository()
      ..petOwnersByUserId[1] = roberto
      ..clinicsByAccountId[20] = vetSur
      ..vetsByUserId[3] = drMendoza;
    pets = FakePetsRepository()
      ..add(pet())
      ..patientsByClinic[5] = [1]
      ..clinicsByPet[1] = [vetSur];
    consultations = FakeConsultationsRepository();
    external = FakeExternalProfilesService();
  });

  Future<void> pumpApp(WidgetTester tester, {required String token}) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildApp(
        storage: InMemorySessionStorage(initialToken: token),
        authRepository: auth,
        profilesRepository: profiles,
        petsRepository: pets,
        consultationsRepository: consultations,
        externalProfilesService: external,
        imagePicker: FakeImagePicker(),
        useGoogleFonts: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) => tapOn(tester, find.byKey(Key(key)));

  Future<void> type(WidgetTester tester, String key, String text) async {
    final field = find.byKey(Key(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> openWorkspace(WidgetTester tester) async {
    await tapOn(tester, find.text('Consultas'));
    await tapOn(tester, find.text('Max'));
    await tapOn(tester, find.text('Ver consulta en curso'));
  }

  testWidgets('el veterinario registra una consulta completa (US01 y US02)', (tester) async {
    await pumpApp(tester, token: 'jwt-vet');

    // Pestaña Consultas: elige a Max, que aún no tiene consultas.
    await tapOn(tester, find.text('Consultas'));
    await tapOn(tester, find.text('Max'));
    expect(find.text('Aún no tiene consultas'), findsOneWidget);

    // Nueva consulta, con Max ya elegido.
    await tapKey(tester, 'consultations.new');
    expect(find.text('Max'), findsOneWidget);
    await tapKey(tester, 'consultation.submit');
    expect(find.text('Describe el motivo de la consulta.'), findsOneWidget);
    expect(consultations.writes, 0);
    await type(tester, 'consultation.reason', 'Lamido de pata');
    await tapKey(tester, 'consultation.room');
    await tapOn(tester, find.text('Consultorio 1').last);
    await tapKey(tester, 'consultation.submit');
    expect(consultations.lastCreate!.clinicId, 5);
    expect(consultations.lastCreate!.consultingRoomId, 3);

    // Consulta creada: se inicia.
    expect(find.text('Consulta N.° 100'), findsOneWidget);
    expect(find.text('Francisco Mendoza'), findsOneWidget);
    await tapKey(tester, 'workspace.start');
    expect(find.text('Paso 1 de 6'), findsOneWidget);

    // Fase 1: el motivo viene de la consulta y la evolución es obligatoria.
    await tapKey(tester, 'workspace.next');
    expect(find.text('Indica hace cuánto empezó.'), findsOneWidget);
    await tapOn(tester, find.text('3 a 5 días'));
    await tapOn(tester, find.text('Eritema visible'));
    await type(tester, 'anamnesis.symptom', 'Cojera');
    await tapKey(tester, 'workspace.next');
    expect(consultations.lastAnamnesis!.chiefComplaint, 'Lamido de pata');
    expect(consultations.lastAnamnesis!.evolutionTime, '3 a 5 días');
    // "Cojera" se escribió sin pulsar Agregar y aun así se registra.
    expect(consultations.lastAnamnesis!.symptoms, ['Eritema visible', 'Cojera']);

    // Fase 2: constantes (con coma decimal) y un hallazgo.
    expect(find.text('Paso 2 de 6'), findsOneWidget);
    await type(tester, 'assessment.weight', '28,5');
    await type(tester, 'assessment.temperature', '50');
    await type(tester, 'assessment.heartRate', '115');
    await type(tester, 'assessment.respiratoryRate', '24');
    await tapKey(tester, 'assessment.submit');
    expect(find.text('Entre 30 y 45 °C.'), findsOneWidget);
    await type(tester, 'assessment.temperature', '38.6');
    await tapKey(tester, 'assessment.submit');
    expect(consultations.lastAssessment!.vitalSigns.weightKg, 28.5);
    expect(find.text('Mediciones registradas (1)'), findsOneWidget);
    // Espera a que el aviso deje de tapar el botón.
    await tester.pump(const Duration(seconds: 3));

    await tapKey(tester, 'findings.add');
    await tapKey(tester, 'finding.bodySystem');
    await tapOn(tester, find.text('Piel y pelaje').last);
    await type(tester, 'finding.description', 'Eritema interdigital');
    await tapKey(tester, 'clinicalSheet.submit');
    expect(find.text('Eritema interdigital'), findsOneWidget);

    // Fase 5: diagnóstico principal y reevaluación.
    await tapKey(tester, 'workspace.next');
    expect(find.text('Paso 5 de 6'), findsOneWidget);
    await tapKey(tester, 'diagnosis.submit');
    expect(find.text('Selecciona el tipo.'), findsOneWidget);
    await tapOn(tester, find.text('Presuntivo'));
    await type(tester, 'diagnosis.description', 'Sarna');
    await tapKey(tester, 'diagnosis.submit');
    expect(find.text('Sarna'), findsOneWidget);

    await tapOn(tester, find.text('Reevaluar'));
    await tapOn(tester, find.text('Definitivo'));
    await type(tester, 'diagnosis.description', 'Pododermatitis');
    await tapKey(tester, 'clinicalSheet.submit');
    expect(find.text('Pododermatitis'), findsOneWidget);
    expect(find.text('Diagnósticos anteriores (1)'), findsOneWidget);
    expect(consultations.byPet[1]!.single.diagnoses.first.status, DiagnosisStatus.superseded);

    // Fase 6: finalizar deja el registro de solo lectura.
    await tapKey(tester, 'workspace.next');
    expect(find.text('Todo listo'), findsOneWidget);
    await tapKey(tester, 'workspace.next');
    await tapKey(tester, 'dialog.confirm');
    expect(consultations.byPet[1]!.single.status, ConsultationStatus.completed);
    expect(find.byKey(const Key('workspace.next')), findsNothing);
    expect(find.byKey(const Key('workspace.menu')), findsNothing);
    expect(find.textContaining('Atención finalizada por Francisco Mendoza'), findsOneWidget);

    // Al volver, la lista ya muestra la consulta finalizada.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Finalizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no se puede finalizar con datos pendientes y la lista lleva a la fase', (
    tester,
  ) async {
    consultations.add(consultation(status: ConsultationStatus.inProgress, anamnesis: anamnesis()));
    await pumpApp(tester, token: 'jwt-vet');
    await openWorkspace(tester);
    // Abre en la primera fase sin datos.
    expect(find.text('Paso 2 de 6'), findsOneWidget);

    await tapKey(tester, 'phase.completion');
    final finish = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('workspace.next')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(finish.onPressed, isNull);
    await tapOn(tester, find.text('Registrar un diagnóstico principal'));
    expect(find.text('Paso 5 de 6'), findsOneWidget);

    // Las fases de AI Assistance aún no se pueden abrir.
    await tapKey(tester, 'phase.images');
    expect(find.text('Paso 5 de 6'), findsOneWidget);
  });

  testWidgets('lo escrito se conserva al cambiar de fase y avisa antes de salir', (tester) async {
    consultations.add(consultation(status: ConsultationStatus.inProgress));
    await pumpApp(tester, token: 'jwt-vet');
    await openWorkspace(tester);

    await type(tester, 'anamnesis.previousTreatments', 'Antibiótico');
    await tapKey(tester, 'phase.diagnosis');
    await tapKey(tester, 'phase.anamnesis');
    expect(find.text('Antibiótico'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la consulta?'), findsOneWidget);
    await tapOn(tester, find.text('Volver'));
    expect(find.text('Consulta N.° 1'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapKey(tester, 'dialog.confirm');
    expect(find.text('Consulta N.° 1'), findsNothing);
    expect(consultations.writes, 0);
  });

  testWidgets('si falta un dato fuera de la pantalla, la lleva al error y lo borra al corregir', (
    tester,
  ) async {
    consultations.add(consultation(status: ConsultationStatus.inProgress));
    await pumpApp(tester, token: 'jwt-vet');
    tester.view.physicalSize = const Size(1170, 1800);
    await openWorkspace(tester);

    final error = find.text('Indica hace cuánto empezó.');
    await tapKey(tester, 'workspace.next');
    expect(error, findsOneWidget);
    final bottomBar = tester.getTopLeft(find.byKey(const Key('workspace.next'))).dy;
    expect(tester.getBottomLeft(find.text('Tiempo de evolución *')).dy, lessThan(bottomBar));
    expect(tester.getBottomLeft(find.text('Menos de 24 h')).dy, lessThan(bottomBar));

    await tapOn(tester, find.text('3 a 5 días'));
    expect(error, findsNothing);
  });

  testWidgets('cancelar pide el motivo y cierra la consulta', (tester) async {
    consultations.add(consultation(status: ConsultationStatus.inProgress));
    await pumpApp(tester, token: 'jwt-vet');
    await openWorkspace(tester);

    await tapKey(tester, 'workspace.menu');
    await tapKey(tester, 'workspace.cancel');
    await tapKey(tester, 'cancel.confirm');
    expect(find.text('El motivo es obligatorio.'), findsOneWidget);
    await type(tester, 'cancel.reason', 'El tutor no asistió');
    await tapKey(tester, 'cancel.confirm');
    expect(find.textContaining('Motivo: El tutor no asistió'), findsOneWidget);
    expect(consultations.byPet[1]!.single.status, ConsultationStatus.cancelled);
  });

  testWidgets('si la API rechaza un hallazgo, la hoja no se cierra ni pierde el texto', (
    tester,
  ) async {
    consultations.add(consultation(status: ConsultationStatus.inProgress, anamnesis: anamnesis()));
    await pumpApp(tester, token: 'jwt-vet');
    await openWorkspace(tester);

    await tapKey(tester, 'findings.add');
    await tapKey(tester, 'finding.bodySystem');
    await tapOn(tester, find.text('Ojos').last);
    await type(tester, 'finding.description', 'Opacidad');
    consultations.nextError = const ClinicalAttentionException(
      ClinicalAttentionErrorCode.notAllowed,
    );
    await tapKey(tester, 'clinicalSheet.submit');
    expect(find.text('Opacidad'), findsOneWidget);
    expect(find.text('No tienes permiso para esta consulta.'), findsWidgets);

    await tapKey(tester, 'clinicalSheet.submit');
    expect(find.byKey(const Key('clinicalSheet.submit')), findsNothing);
    expect(consultations.byPet[1]!.single.findings.single.description, 'Opacidad');
  });

  testWidgets('desde la ficha del paciente, el veterinario abre una consulta nueva', (
    tester,
  ) async {
    await pumpApp(tester, token: 'jwt-vet');
    await tapOn(tester, find.text('Max'));
    await tapKey(tester, 'pet.newConsultation');
    expect(find.text('Nueva consulta'), findsOneWidget);
    await type(tester, 'consultation.reason', 'Control');
    await tapKey(tester, 'consultation.submit');
    expect(consultations.lastCreate!.petId, 1);
    // Reemplaza al formulario: atrás vuelve a la ficha.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Perfil de mascota'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
  });

  testWidgets('consulta que no existe muestra el error y permite reintentar', (tester) async {
    consultations
      ..add(consultation(status: ConsultationStatus.inProgress))
      ..nextError = null;
    await pumpApp(tester, token: 'jwt-vet');
    await tapOn(tester, find.text('Consultas'));
    await tapOn(tester, find.text('Max'));
    consultations.nextError = const ClinicalAttentionException(
      ClinicalAttentionErrorCode.noConnection,
    );
    await tapOn(tester, find.text('Ver consulta en curso'));
    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    await tapOn(tester, find.text('Reintentar'));
    expect(find.text('Paso 1 de 6'), findsOneWidget);
  });

  testWidgets('el dueño ve la historia (MM-06) y el detalle (MM-07) sin poder registrar', (
    tester,
  ) async {
    consultations
      ..add(
        consultation(anamnesis: anamnesis(), assessments: [assessment()], diagnoses: [diagnosis()]),
      )
      ..add(
        consultation(
          id: 2,
          reason: 'Vacuna',
          status: ConsultationStatus.cancelled,
          date: DateTime(2026, 2, 2),
          cancellationReason: 'Reprogramada',
        ),
      );
    await pumpApp(tester, token: 'jwt-owner');
    expect(find.text('Consultas'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Historia clínica'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapOn(tester, find.text('Historia clínica'));
    expect(find.text('Historia clínica de Max'), findsOneWidget);
    expect(find.byKey(const Key('history.newConsultation')), findsNothing);
    await tapOn(tester, find.text('Cancelada (1)'));
    expect(find.text('Vacuna'), findsOneWidget);
    expect(find.text('Pododermatitis'), findsNothing);
    await tapOn(tester, find.text('Todas (2)'));

    await tapOn(tester, find.text('Pododermatitis'));
    expect(find.text('Consulta N.° 1'), findsOneWidget);
    expect(find.textContaining('CMVP 9841'), findsOneWidget);
    expect(find.text('“Lamido de pata”'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pododermatitis alérgica'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reevaluar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla pequeña con letra grande: ninguna fase se desborda', (tester) async {
    consultations.add(
      consultation(
        status: ConsultationStatus.inProgress,
        anamnesis: const Anamnesis(
          id: 1,
          chiefComplaint: 'Lamido de pata',
          evolutionTime: '3 a 5 días',
          symptoms: ['Un síntoma escrito por el veterinario, largo, que ocupa más de una línea'],
        ),
        assessments: [assessment()],
        diagnoses: [
          diagnosis(id: 1, status: DiagnosisStatus.superseded),
          diagnosis(id: 2, previousDiagnosisId: 1),
        ],
      ),
    );
    await pumpApp(tester, token: 'jwt-vet');
    await openWorkspace(tester);
    tester.view.physicalSize = const Size(320, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final phase in ['anamnesis', 'assessment', 'diagnosis', 'completion']) {
      await tapKey(tester, 'phase.$phase');
      expect(tester.takeException(), isNull, reason: phase);
    }
  });
}
