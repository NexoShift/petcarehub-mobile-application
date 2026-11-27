import 'package:flutter/foundation.dart';

import '../domain/model/aggregates/clinical_consultation.dart';
import '../domain/model/clinical_attention_exception.dart';
import '../domain/repositories/consultations_repository.dart';

/// Consultas por mascota, con caché simple para no repetir la llamada al
/// cambiar de mascota en el dashboard.
class ConsultationsStore extends ChangeNotifier {
  ConsultationsStore({required this._repository});

  final ConsultationsRepository _repository;

  final Map<int, List<ClinicalConsultation>> _byPet = {};
  final Set<int> _loading = {};
  final Map<int, ClinicalAttentionErrorCode> _errors = {};

  /// Cambia al cerrar sesión: descarta respuestas pedidas por el usuario anterior.
  int _generation = 0;

  List<ClinicalConsultation>? consultationsOf(int petId) => _byPet[petId];
  bool isLoading(int petId) => _loading.contains(petId);
  ClinicalAttentionErrorCode? errorOf(int petId) => _errors[petId];

  ClinicalConsultation? find({required int petId, required int consultationId}) =>
      _byPet[petId]?.where((c) => c.id == consultationId).firstOrNull;

  Future<void> loadForPet(int petId, {bool force = false}) async {
    if (_loading.contains(petId) || (!force && _byPet.containsKey(petId))) return;
    final generation = _generation;
    _loading.add(petId);
    _errors.remove(petId);
    notifyListeners();
    try {
      final consultations = await _repository.getByPet(petId);
      if (generation == _generation) _byPet[petId] = _sorted(consultations);
    } on ClinicalAttentionException catch (error) {
      if (generation == _generation) _errors[petId] = error.code;
    } finally {
      if (generation == _generation) {
        _loading.remove(petId);
        notifyListeners();
      }
    }
  }

  /// Refleja en la lista una consulta que se acaba de crear o modificar. Si la
  /// lista de esa mascota aún no se cargó, no hace falta: se pedirá completa.
  void upsert(ClinicalConsultation consultation) {
    final current = _byPet[consultation.petId];
    if (current == null) return;
    _byPet[consultation.petId] = _sorted([
      consultation,
      ...current.where((c) => c.id != consultation.id),
    ]);
    notifyListeners();
  }

  /// Al cerrar sesión no deben quedar datos de otro usuario.
  void clear() {
    _generation++;
    _byPet.clear();
    _loading.clear();
    _errors.clear();
    notifyListeners();
  }

  static List<ClinicalConsultation> _sorted(List<ClinicalConsultation> consultations) =>
      [...consultations]..sort((a, b) => b.date.compareTo(a.date));
}
