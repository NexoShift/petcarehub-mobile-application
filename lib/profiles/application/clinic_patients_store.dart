import 'package:flutter/foundation.dart';

import '../../shared/domain/api_error.dart';
import '../domain/model/pet.dart';
import '../domain/model/species.dart';
import '../domain/repositories/pets_repository.dart';
import 'pets_store.dart' show LoadStatus;

/// Directorio de pacientes de la clínica (MM-13), para el veterinario.
class ClinicPatientsStore extends ChangeNotifier {
  ClinicPatientsStore({required this._repository});

  final PetsRepository _repository;

  LoadStatus _status = LoadStatus.idle;
  List<Pet> _patients = const [];
  String? _error;
  String _query = '';
  Species? _speciesFilter;

  LoadStatus get status => _status;
  String? get error => _error;
  List<Pet> get allPatients => _patients;
  String get query => _query;
  Species? get speciesFilter => _speciesFilter;

  /// Pacientes filtrados por texto (nombre, código o raza) y especie.
  List<Pet> get patients {
    final q = _query.trim().toLowerCase();
    return _patients.where((pet) {
      final matchesSpecies = _speciesFilter == null || pet.species == _speciesFilter;
      final matchesText = q.isEmpty ||
          pet.name.toLowerCase().contains(q) ||
          pet.petCode.toLowerCase().contains(q) ||
          (pet.breed ?? '').toLowerCase().contains(q);
      return matchesSpecies && matchesText;
    }).toList();
  }

  int countOf(Species species) => _patients.where((p) => p.species == species).length;

  Future<void> load(int clinicId, {bool force = false}) async {
    if (_status == LoadStatus.loading) return;
    if (!force && _status == LoadStatus.loaded) return;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _patients = [...await _repository.getClinicPatients(clinicId)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _status = LoadStatus.loaded;
    } on ApiError catch (error) {
      _error = error.message;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void filterBySpecies(Species? species) {
    _speciesFilter = species;
    notifyListeners();
  }

  /// Paso 1 del registro: buscar la mascota con el código que da el dueño.
  Future<Pet?> findByCode(String petCode) => _repository.findPetByCode(petCode);

  bool isPatient(int petId) => _patients.any((p) => p.id == petId);

  /// Paso 2: registrarla como paciente y recargar la lista.
  Future<void> register({required int clinicId, required Pet pet}) async {
    await _repository.registerClinicPatient(clinicId: clinicId, petId: pet.id);
    await load(clinicId, force: true);
  }

  void clear() {
    _patients = const [];
    _status = LoadStatus.idle;
    _error = null;
    _query = '';
    _speciesFilter = null;
    notifyListeners();
  }
}
