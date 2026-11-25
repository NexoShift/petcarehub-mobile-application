import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petcare_mobile_application/app/dependencies.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/profiles/domain/model/person_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_owner.dart';

import '../support/fakes.dart';

/// Pruebas de punta a punta de la UI con repositorios falsos (sin red).
void main() {
  late FakeAuthRepository auth;
  late FakeProfilesRepository profiles;
  late FakePetsRepository pets;

  setUp(() {
    auth = FakeAuthRepository()..addAccount('Secreta123', ownerSession());
    profiles = FakeProfilesRepository();
    pets = FakePetsRepository();
  });

  Future<void> pumpApp(WidgetTester tester, {String? savedToken}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildApp(
        storage: InMemorySessionStorage(initialToken: savedToken),
        authRepository: auth,
        profilesRepository: profiles,
        petsRepository: pets,
        consultationsRepository: FakeConsultationsRepository(),
        imagePicker: FakeImagePicker(),
        useGoogleFonts: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('sin sesión muestra la bienvenida (MM-01)', (tester) async {
    await pumpApp(tester);
    expect(find.text('PetCare Hub'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });

  testWidgets('login con clave incorrecta muestra el error', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Iniciar Sesión'));

    await tester.enterText(find.byKey(const Key('signIn.email')), 'roberto@example.com');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('signIn.password')),
        matching: find.byType(TextField),
      ),
      'mala-clave',
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Iniciar Sesión'));

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('login valida los campos vacíos sin llamar a la API', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Iniciar Sesión'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Iniciar Sesión'));

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('dueño con perfil inicia sesión y llega al inicio', (tester) async {
    profiles.petOwnersByUserId[1] = const PetOwner(
      id: 1,
      userId: 1,
      firstName: 'Roberto',
      lastName: 'García',
      email: 'roberto@example.com',
    );
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Iniciar Sesión'));

    await tester.enterText(find.byKey(const Key('signIn.email')), 'roberto@example.com');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('signIn.password')),
        matching: find.byType(TextField),
      ),
      'Secreta123',
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Iniciar Sesión'));

    expect(find.text('¡Hola, Roberto!'), findsOneWidget);
  });

  testWidgets('registro de dueño: paso 1, paso 2 prellenado y home', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Comenzar'));
    expect(find.text('Crear Cuenta'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signUp.fullName')), 'Ana Torres Ruiz');
    await tester.enterText(find.byKey(const Key('signUp.email')), 'ana@example.com');
    await tester.enterText(find.byKey(const Key('signUp.phone')), '987654321');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('signUp.password')),
        matching: find.byType(TextField),
      ),
      'S3cur3P@ss',
    );
    await tester.pump();
    expect(find.text('Seguridad: Fuerte'), findsOneWidget);

    // Sin aceptar términos no avanza.
    await tapAndSettle(tester, find.byKey(const Key('signUp.submit')));
    expect(find.text('Debes aceptar los términos para continuar'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('signUp.terms')));
    await tapAndSettle(tester, find.byKey(const Key('signUp.submit')));

    // Paso 2 con los datos del paso 1.
    expect(find.text('Completa tu perfil'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ana'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Torres Ruiz'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '987654321'), findsOneWidget);

    await tapAndSettle(tester, find.text('Femenino'));
    await tapAndSettle(tester, find.byKey(const Key('owner.submit')));

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    final saved = profiles.petOwnersByUserId.values.single;
    expect(saved.phoneNumber, '+51987654321');
    expect(profiles.lastSex, PersonSex.female);
  });

  testWidgets('registro con correo repetido muestra el error', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Comenzar'));

    await tester.enterText(find.byKey(const Key('signUp.fullName')), 'Roberto García');
    await tester.enterText(find.byKey(const Key('signUp.email')), 'roberto@example.com');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('signUp.password')),
        matching: find.byType(TextField),
      ),
      'Secreta123',
    );
    await tapAndSettle(tester, find.byKey(const Key('signUp.terms')));
    await tapAndSettle(tester, find.byKey(const Key('signUp.submit')));

    expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
  });

  testWidgets('registro de clínica lleva al paso 2 de la clínica', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Comenzar'));

    await tapAndSettle(tester, find.byKey(const Key('signUp.type.clinic')));
    await tester.enterText(find.byKey(const Key('signUp.fullName')), 'Francisco Mendoza');
    await tester.enterText(find.byKey(const Key('signUp.email')), 'admin@vetsur.pe');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('signUp.password')),
        matching: find.byType(TextField),
      ),
      'Secreta123',
    );
    await tapAndSettle(tester, find.byKey(const Key('signUp.terms')));
    await tapAndSettle(tester, find.byKey(const Key('signUp.submit')));

    expect(find.text('Registra tu clínica'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('clinic.name')), 'Clínica VetSur');
    await tapAndSettle(tester, find.byKey(const Key('clinic.submit')));

    // El admin llega al directorio de pacientes (MM-13) de su clínica.
    expect(find.text('Clínica VetSur'), findsOneWidget);
    expect(find.text('Aún no tienes pacientes'), findsOneWidget);
  });

  testWidgets('con token guardado y perfil entra directo al inicio', (tester) async {
    profiles.petOwnersByUserId[1] = const PetOwner(
      id: 1,
      userId: 1,
      firstName: 'Roberto',
      lastName: 'García',
      email: 'roberto@example.com',
    );
    await pumpApp(tester, savedToken: 'jwt-owner');

    expect(find.text('¡Hola, Roberto!'), findsOneWidget);

    await tapAndSettle(tester, find.text('Perfil'));
    await tapAndSettle(tester, find.text('Cerrar sesión'));
    expect(find.text('Comenzar'), findsOneWidget);
  });

  testWidgets('olvidé mi contraseña envía el correo', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, find.text('Iniciar Sesión'));
    await tester.enterText(find.byKey(const Key('signIn.email')), 'roberto@example.com');
    await tapAndSettle(tester, find.text('¿Olvidaste tu contraseña?'));
    await tapAndSettle(tester, find.text('Enviar enlace'));

    expect(auth.recoveryRequests, ['roberto@example.com']);
    expect(find.textContaining('te enviamos un enlace'), findsOneWidget);
  });
}
