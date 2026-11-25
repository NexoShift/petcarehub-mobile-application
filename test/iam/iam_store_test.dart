import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/iam/application/iam_store.dart';
import 'package:petcare_mobile_application/iam/domain/model/account_type.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemorySessionStorage storage;
  late IamStore store;

  setUp(() {
    repository = FakeAuthRepository()..addAccount('Secreta123', ownerSession());
    storage = InMemorySessionStorage();
    store = IamStore(repository: repository, storage: storage);
  });

  test('empieza en unknown', () {
    expect(store.status, AuthStatus.unknown);
  });

  test('sign-in guarda el token y queda autenticado', () async {
    await store.signIn(email: ' roberto@example.com ', password: 'Secreta123');

    expect(store.status, AuthStatus.authenticated);
    expect(store.session!.isPetOwner, isTrue);
    expect(storage.token, 'jwt-owner');
  });

  test('sign-in con clave incorrecta lanza 401 y no cambia el estado', () async {
    await expectLater(
      store.signIn(email: 'roberto@example.com', password: 'mala'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 401)),
    );
    expect(store.status, AuthStatus.unknown);
    expect(storage.token, isNull);
  });

  test('sign-up crea la cuenta y entra de una vez', () async {
    await store.signUp(
      email: 'nuevo@example.com',
      password: 'Secreta123',
      accountType: AccountType.clinic,
    );

    expect(store.isAuthenticated, isTrue);
    expect(store.session!.isClinicAdmin, isTrue);
  });

  test('restore sin token guardado queda unauthenticated', () async {
    await store.restoreSession();
    expect(store.status, AuthStatus.unauthenticated);
  });

  test('restore con token válido entra directo', () async {
    storage = InMemorySessionStorage(initialToken: 'jwt-owner');
    store = IamStore(repository: repository, storage: storage);

    await store.restoreSession();

    expect(store.isAuthenticated, isTrue);
    expect(store.session!.email, 'roberto@example.com');
  });

  test('restore con token vencido lo borra', () async {
    storage = InMemorySessionStorage(initialToken: 'vencido');
    store = IamStore(repository: repository, storage: storage);

    await store.restoreSession();

    expect(store.status, AuthStatus.unauthenticated);
    expect(await storage.read(), isNull);
  });

  test('restore sin internet NO borra el token y relanza el error', () async {
    storage = InMemorySessionStorage(initialToken: 'jwt-owner');
    store = IamStore(repository: repository, storage: storage);
    repository.nextError = const ApiError(status: 0, message: 'sin red');

    await expectLater(store.restoreSession(), throwsA(isA<ApiError>()));
    expect(await storage.read(), 'jwt-owner');
  });

  test('un 401 de la API (sesión vencida) cierra la sesión', () async {
    await store.signIn(email: 'roberto@example.com', password: 'Secreta123');

    storage.onUnauthorized();
    await Future<void>.delayed(Duration.zero);

    expect(store.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
  });

  test('sign-out borra todo', () async {
    await store.signIn(email: 'roberto@example.com', password: 'Secreta123');
    await store.signOut();

    expect(store.session, isNull);
    expect(storage.token, isNull);
  });

  test('cambiar contraseña con la actual correcta', () async {
    repository.addAccount('Temporal123', clinicMemberSession(mustChangePassword: true));
    await store.signIn(email: 'vet@vetsur.pe', password: 'Temporal123');
    expect(store.session!.mustChangePassword, isTrue);

    await store.changePassword(currentPassword: 'Temporal123', newPassword: 'NuevaClave1');

    expect(store.session!.mustChangePassword, isFalse);
    await store.signOut();
    await store.signIn(email: 'vet@vetsur.pe', password: 'NuevaClave1');
    expect(store.isAuthenticated, isTrue);
  });

  test('cambiar contraseña con la actual incorrecta lanza 400 y no cambia nada', () async {
    await store.signIn(email: 'roberto@example.com', password: 'Secreta123');

    await expectLater(
      store.changePassword(currentPassword: 'mala', newPassword: 'NuevaClave1'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 400)),
    );
    expect(store.isAuthenticated, isTrue);
  });
}
