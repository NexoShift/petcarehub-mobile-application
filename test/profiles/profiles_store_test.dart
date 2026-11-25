import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/iam/application/iam_store.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/profiles/application/profiles_store.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_owner.dart';


import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfilesRepository repository;
  late IamStore iam;
  late ProfilesStore store;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('Secreta123', ownerSession())
      ..addAccount('Secreta123', clinicAdminSession())
      ..addAccount('Secreta123', clinicMemberSession());
    repository = FakeProfilesRepository();
    iam = IamStore(repository: auth, storage: InMemorySessionStorage());
    store = ProfilesStore(repository: repository, iamStore: iam);
  });

  test('dueño sin perfil queda en missing y al completarlo pasa a complete', () async {
    await store.loadFor(ownerSession());
    expect(store.status, ProfileStatus.missing);



    expect(store.status, ProfileStatus.complete);
    expect(store.displayName, 'Roberto');
    expect(store.draft, isNull);
  });

  test('dueño con perfil queda en complete', () async {
    repository.petOwnersByUserId[1] = const PetOwner(
      id: 1,
      userId: 1,
      firstName: 'Roberto',
      lastName: 'García',
      email: 'roberto@example.com',
    );
    await store.loadFor(ownerSession());
    expect(store.status, ProfileStatus.complete);
  });

  test('admin de clínica sin clínica queda en missing', () async {
    await store.loadFor(clinicAdminSession());
    expect(store.status, ProfileStatus.missing);

    await store.completeClinic(session: clinicAdminSession(), name: 'VetSur');
    expect(store.displayName, 'VetSur');
  });

  test('vet miembro no tiene paso 2', () async {
    await store.loadFor(clinicMemberSession());
    expect(store.status, ProfileStatus.complete);
  });

  test('al cerrar sesión vuelve a unknown', () async {
    await iam.signIn(email: 'roberto@example.com', password: 'Secreta123');
    await store.loadFor(iam.session!);
    await iam.signOut();
    expect(store.status, ProfileStatus.unknown);
  });


}
