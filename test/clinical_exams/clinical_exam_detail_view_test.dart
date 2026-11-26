import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petcare_mobile_application/clinical_exams/application/clinical_exams_store.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_status.dart';
import 'package:petcare_mobile_application/clinical_exams/presentation/views/clinical_exam_detail_view.dart';
import 'package:petcare_mobile_application/iam/application/iam_store.dart';
import 'package:petcare_mobile_application/iam/domain/model/user_session.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/infrastructure/image_picker_service.dart';
import 'package:provider/provider.dart';

import '../support/clinical_exams_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeClinicalExamsRepository repository;

  setUp(() => repository = FakeClinicalExamsRepository());

  Future<void> pumpDetail(WidgetTester tester, UserSession session, {int examId = 1}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final iam = IamStore(
      repository: FakeAuthRepository()..addAccount('Secreta123', session),
      storage: InMemorySessionStorage(),
    );
    await iam.signIn(email: session.email, password: 'Secreta123');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: iam),
          ChangeNotifierProvider(create: (_) => ClinicalExamsStore(repository: repository)),
          Provider<ImagePickerService>.value(value: FakeImagePicker()),
        ],
        child: MaterialApp(home: ClinicalExamDetailView(examId: examId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the veterinarian takes the exam from requested to completed', (tester) async {
    repository.add(clinicalExam());
    await pumpDetail(tester, clinicMemberSession());

    expect(find.text('Solicitado'), findsWidgets);
    await tester.tap(find.text('Iniciar examen'));
    await tester.pumpAndSettle();
    expect(repository.exams[1]!.status, ExamStatus.inProcess);

    await tester.tap(find.text('Registrar resultado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('result.submit')));
    await tester.pump();
    expect(find.text('Escribe el resumen del resultado'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('result.summary')), 'Valores normales');
    await tester.tap(find.byKey(const Key('result.submit')));
    await tester.pumpAndSettle();
    expect(find.text('Resultado pendiente de validación'), findsOneWidget);

    await tester.tap(find.text('Validar resultado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Resultado validado'), findsWidgets);

    await tester.tap(find.text('Completar examen'));
    await tester.pumpAndSettle();
    expect(repository.exams[1]!.status, ExamStatus.completed);
    expect(find.byKey(const Key('exam.next')), findsNothing);
  });

  testWidgets('the veterinarian cancels with a reason', (tester) async {
    repository.add(clinicalExam());
    await pumpDetail(tester, clinicMemberSession());

    await tester.tap(find.byKey(const Key('exam.cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cancel.reason')), 'El tutor desistió');
    await tester.tap(find.byKey(const Key('cancel.confirm')));
    await tester.pumpAndSettle();

    expect(repository.exams[1]!.status, ExamStatus.cancelled);
    expect(find.text('Motivo: El tutor desistió'), findsOneWidget);
  });

  testWidgets('the owner reads the exam without actions', (tester) async {
    repository.add(clinicalExam(status: ExamStatus.inProcess));
    await pumpDetail(tester, ownerSession());

    expect(
      find.text('El resultado aparecerá aquí cuando el veterinario lo valide.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('exam.next')), findsNothing);
    expect(find.byKey(const Key('exam.cancel')), findsNothing);
    expect(find.text('Adjuntar foto'), findsNothing);
  });
}
