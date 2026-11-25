import 'package:flutter/foundation.dart';

import '../../shared/domain/api_error.dart';
import '../domain/model/consultation_summary.dart';
import '../domain/repositories/consultations_repository.dart';

/// Consultas por mascota, con caché simple para no repetir la llamada al
/// cambiar de mascota en el dashboard.
class ConsultationsStore extends ChangeNotifier {
  ConsultationsStore({required this._repository});

  final ConsultationsRepository _repository;

  final Map<int, List<ConsultationSummary>> _byPet = {};
  final Set<int> _loading = {};
  final Map<int, String> _errors = {};

  List<ConsultationSummary>? consultationsOf(int petId) => _byPet[petId];
  bool isLoading(int petId) => _loading.contains(petId);
  String? errorOf(int petId) => _errors[petId];

  Future<void> loadForPet(int petId, {bool force = false}) async {
    if (_loading.contains(petId) || (!force && _byPet.containsKey(petId))) return;
    _loading.add(petId);
    _errors.remove(petId);
    notifyListeners();
    try {
      _byPet[petId] = [...await _repository.getByPet(petId)]
        ..sort((a, b) => b.date.compareTo(a.date));
    } on ApiError catch (error) {
      _errors[petId] = error.message;
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  /// Al cerrar sesión no deben quedar datos de otro usuario.
  void clear() {
    _byPet.clear();
    _errors.clear();
    notifyListeners();
  }
}
