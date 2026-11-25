import 'package:flutter/foundation.dart';

import '../../iam/application/iam_store.dart';
import '../../iam/domain/model/user_session.dart';
import '../domain/model/clinic.dart';
import '../domain/model/person_sex.dart';
import '../domain/model/pet_owner.dart';
import '../domain/model/profile_draft.dart';
import '../domain/repositories/profiles_repository.dart';

enum ProfileStatus { unknown, missing, complete }

/// Estado del perfil del usuario autenticado (paso 2 del onboarding).
///
/// Escucha a IamStore: si cambia la sesión (login, logout, 401) vuelve a "unknown"
/// para que el router lo cargue de nuevo.
class ProfilesStore extends ChangeNotifier {
  ProfilesStore({required this._repository, required IamStore iamStore}) : _iam = iamStore {
    _iam.addListener(_onSessionChanged);
  }

  final ProfilesRepository _repository;
  final IamStore _iam;

  ProfileStatus _status = ProfileStatus.unknown;
  PetOwner? _petOwner;
  Clinic? _clinic;
  int? _loadedForUserId;

  /// Datos del paso 1 del registro para prellenar el paso 2.
  ProfileDraft? draft;

  ProfileStatus get status => _status;
  PetOwner? get petOwner => _petOwner;
  Clinic? get clinic => _clinic;

  /// Nombre para el saludo del inicio ("¡Hola, Roberto!").
  String get displayName => _petOwner?.firstName ?? _clinic?.name ?? '';

  Future<void> loadFor(UserSession session) async {
    if (session.isPetOwner) {
      _petOwner = await _repository.findPetOwnerByUserId(session.userId);
      _status = _petOwner == null ? ProfileStatus.missing : ProfileStatus.complete;
    } else if (session.isClinicAdmin) {
      _clinic = await _repository.findClinicByAccountId(session.accountId);
      _status = _clinic == null ? ProfileStatus.missing : ProfileStatus.complete;
    } else {
      // Vet miembro: su perfil lo registra la clínica desde la web.
      _status = ProfileStatus.complete;
    }
    _loadedForUserId = session.userId;
    notifyListeners();
  }

  Future<void> completePetOwner({
    required UserSession session,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    PersonSex? sex,
  }) async {
    _petOwner = await _repository.createPetOwner(
      userId: session.userId,
      email: session.email,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phoneNumber: phoneNumber,
      sex: sex,
    );
    _complete();
  }

  Future<void> completeClinic({
    required UserSession session,
    required String name,
    String? ruc,
    String? address,
    String? phoneNumber,
  }) async {
    _clinic = await _repository.createClinic(
      accountId: session.accountId,
      name: name.trim(),
      ruc: ruc,
      address: address,
      phoneNumber: phoneNumber,
    );
    _complete();
  }

  void _complete() {
    draft = null;
    _status = ProfileStatus.complete;
    notifyListeners();
  }

  void _onSessionChanged() {
    if (_iam.session?.userId == _loadedForUserId) return;
    _status = ProfileStatus.unknown;
    _petOwner = null;
    _clinic = null;
    _loadedForUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _iam.removeListener(_onSessionChanged);
    super.dispose();
  }
}
