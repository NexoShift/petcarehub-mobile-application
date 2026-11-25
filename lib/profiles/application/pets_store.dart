import 'package:flutter/foundation.dart';

import '../../shared/domain/api_error.dart';
import '../../shared/domain/picked_image.dart';
import '../domain/model/clinic.dart';
import '../domain/model/pet.dart';
import '../domain/model/pet_draft.dart';
import '../domain/repositories/pets_repository.dart';

enum LoadStatus { idle, loading, loaded, error }

/// Ficha de la mascota con las clínicas donde es paciente (MM-05).
typedef PetDetail = ({Pet pet, List<Clinic> clinics});

/// Mascotas del dueño autenticado y la mascota elegida en el dashboard.
class PetsStore extends ChangeNotifier {
  PetsStore({required this._repository});

  final PetsRepository _repository;

  LoadStatus _status = LoadStatus.idle;
  List<Pet> _pets = const [];
  String? _error;
  int? _selectedPetId;

  LoadStatus get status => _status;
  List<Pet> get pets => _pets;
  String? get error => _error;

  /// La mascota destacada en el dashboard (la primera si no eligió otra).
  Pet? get selectedPet =>
      _pets.where((p) => p.id == _selectedPetId).firstOrNull ?? _pets.firstOrNull;

  Pet? byId(int petId) => _pets.where((p) => p.id == petId).firstOrNull;

  Future<void> load(int petOwnerId, {bool force = false}) async {
    if (_status == LoadStatus.loading) return;
    if (!force && _status == LoadStatus.loaded) return;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _pets = await _repository.getPetsByOwner(petOwnerId);
      _status = LoadStatus.loaded;
    } on ApiError catch (error) {
      _error = error.message;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void select(int petId) {
    _selectedPetId = petId;
    notifyListeners();
  }

  /// Registra la mascota y, si hay foto, la sube en la misma petición.
  Future<Pet> create({required int ownerId, required PetDraft draft, PickedImage? image}) async {
    final pet = await _repository.createPet(ownerId: ownerId, draft: draft, image: image);
    _pets = [..._pets, pet];
    _selectedPetId = pet.id;
    notifyListeners();
    return pet;
  }

  Future<Pet> update({required int petId, required PetDraft draft, PickedImage? image}) async {
    var pet = await _repository.updatePet(petId: petId, draft: draft);
    if (image != null) pet = await _repository.updatePetImage(petId: petId, image: image);
    _replace(pet);
    return pet;
  }

  Future<PetDetail> fetchDetail(int petId) async {
    final results = await Future.wait([
      _repository.getPet(petId),
      _repository.getPetClinics(petId),
    ]);
    final pet = results[0] as Pet;
    if (byId(petId) != null) _replace(pet);
    return (pet: pet, clinics: results[1] as List<Clinic>);
  }

  void _replace(Pet pet) {
    _pets = [for (final p in _pets) p.id == pet.id ? pet : p];
    notifyListeners();
  }

  void clear() {
    _pets = const [];
    _status = LoadStatus.idle;
    _error = null;
    _selectedPetId = null;
    notifyListeners();
  }
}
