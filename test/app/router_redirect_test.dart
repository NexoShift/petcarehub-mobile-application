import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/app/app_router.dart';
import 'package:petcare_mobile_application/app/app_routes.dart';
import 'package:petcare_mobile_application/iam/application/iam_store.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/profiles/application/profiles_store.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfilesRepository profilesRepo;
  late IamStore iam;
  late ProfilesStore profiles;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('Secreta123', ownerSession())
      ..addAccount('Secreta123', clinicAdminSession());
    profilesRepo = FakeProfilesRepository();
    iam = IamStore(repository: auth, storage: InMemorySessionStorage());
    profiles = ProfilesStore(repository: profilesRepo, iamStore: iam);
  });

  String? go(String location) => resolveRedirect(location: location, iam: iam, profiles: profiles);

  test('sin saber la sesión todo va a boot', () {
    expect(go(AppRoutes.home), AppRoutes.boot);
    expect(go(AppRoutes.boot), isNull);
  });

  test('sin sesión solo se ven las pantallas públicas', () async {
    await iam.restoreSession();
    expect(go(AppRoutes.boot), AppRoutes.welcome);
    expect(go(AppRoutes.home), AppRoutes.welcome);
    expect(go(AppRoutes.completePetOwner), AppRoutes.welcome);
    expect(go(AppRoutes.signIn), isNull);
    expect(go(AppRoutes.signUp), isNull);
  });

  test('con sesión pero perfil sin cargar va a boot', () async {
    await iam.signIn(email: 'roberto@example.com', password: 'Secreta123');
    expect(go(AppRoutes.signIn), AppRoutes.boot);
  });

  test('dueño sin perfil va al paso 2 del dueño', () async {
    await iam.signIn(email: 'roberto@example.com', password: 'Secreta123');
    await profiles.loadFor(iam.session!);
    expect(go(AppRoutes.home), AppRoutes.completePetOwner);
    expect(go(AppRoutes.completePetOwner), isNull);
  });

  test('admin sin clínica va al paso 2 de la clínica', () async {
    await iam.signIn(email: 'admin@vetsur.pe', password: 'Secreta123');
    await profiles.loadFor(iam.session!);
    expect(go(AppRoutes.boot), AppRoutes.completeClinic);
  });

  test('con perfil completo, login/registro/boot llevan a home', () async {
    await iam.signIn(email: 'admin@vetsur.pe', password: 'Secreta123');
    await profiles.completeClinic(session: iam.session!, name: 'VetSur');
    expect(go(AppRoutes.signIn), AppRoutes.home);
    expect(go(AppRoutes.completeClinic), AppRoutes.home);
    expect(go(AppRoutes.home), isNull);
  });

  test('vet con contraseña temporal solo puede ir a cambiarla', () async {
    auth.addAccount('Temporal123', clinicMemberSession(mustChangePassword: true));
    await iam.signIn(email: 'vet@vetsur.pe', password: 'Temporal123');
    expect(go(AppRoutes.home), AppRoutes.changePassword);
    expect(go(AppRoutes.boot), AppRoutes.changePassword);
    expect(go(AppRoutes.changePassword), isNull);
  });
}
