import 'package:flutter/foundation.dart';

import '../domain/model/aggregates/clinical_consultation.dart';
import '../domain/model/clinical_attention_exception.dart';
import '../domain/model/commands/add_clinical_finding_command.dart';
import '../domain/model/commands/cancel_clinical_consultation_command.dart';
import '../domain/model/commands/create_clinical_consultation_command.dart';
import '../domain/model/commands/reevaluate_diagnosis_command.dart';
import '../domain/model/commands/register_anamnesis_command.dart';
import '../domain/model/commands/register_diagnosis_command.dart';
import '../domain/model/commands/register_physiological_assessment_command.dart';
import '../domain/model/value_objects/pending_item.dart';
import '../domain/repositories/consultations_repository.dart';
import 'consultations_store.dart';

/// La consulta que el veterinario está atendiendo y sus casos de uso.
///
/// Cada caso de uso devuelve true si la API lo aceptó. Si falla, el motivo queda
/// en [error] y la consulta no cambia.
class ConsultationWorkspaceStore extends ChangeNotifier {
  ConsultationWorkspaceStore({required this._repository, required this._consultations});

  final ConsultationsRepository _repository;
  final ConsultationsStore _consultations;

  ClinicalConsultation? _consultation;
  ClinicalAttentionErrorCode? _error;
  List<PendingItem> _pendingItems = const [];
  bool _loading = false;
  bool _saving = false;

  /// Cambia al abrir otra consulta o cerrar sesión: descarta respuestas viejas.
  int _generation = 0;

  ClinicalConsultation? get consultation => _consultation;
  ClinicalAttentionErrorCode? get error => _error;

  /// Lo que faltaba según el backend al intentar finalizar.
  List<PendingItem> get pendingItems => _pendingItems;
  bool get isLoading => _loading;
  bool get isSaving => _saving;

  Future<bool> load(int consultationId) async {
    final generation = ++_generation;
    _consultation = null;
    _loading = true;
    _saving = false;
    _clearError();
    notifyListeners();
    try {
      final consultation = await _repository.getById(consultationId);
      if (generation != _generation) return false;
      _consultation = consultation;
      return true;
    } on ClinicalAttentionException catch (error) {
      if (generation == _generation) _setError(error);
      return false;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> create(CreateClinicalConsultationCommand command) {
    if (_saving) return Future.value(false);
    _generation++;
    _consultation = null;
    return _save(() => _repository.create(command));
  }

  Future<bool> start(int consultationId) => _save(() => _repository.start(consultationId));

  Future<bool> registerAnamnesis(RegisterAnamnesisCommand command) =>
      _save(() => _repository.registerAnamnesis(command));

  Future<bool> registerPhysiologicalAssessment(RegisterPhysiologicalAssessmentCommand command) =>
      _save(() => _repository.registerPhysiologicalAssessment(command));

  Future<bool> addClinicalFinding(AddClinicalFindingCommand command) =>
      _save(() => _repository.addClinicalFinding(command));

  Future<bool> registerDiagnosis(RegisterDiagnosisCommand command) =>
      _save(() => _repository.registerDiagnosis(command));

  Future<bool> reevaluateDiagnosis(ReevaluateDiagnosisCommand command) =>
      _save(() => _repository.reevaluateDiagnosis(command));

  Future<bool> complete(int consultationId) => _save(() => _repository.complete(consultationId));

  Future<bool> cancel(CancelClinicalConsultationCommand command) =>
      _save(() => _repository.cancel(command));

  /// Para errores previos al envío, como un command inválido.
  void reportError(ClinicalAttentionException error) {
    _setError(error);
    notifyListeners();
  }

  void clearError() {
    if (_error == null && _pendingItems.isEmpty) return;
    _clearError();
    notifyListeners();
  }

  /// Al cerrar sesión no deben quedar datos de otro usuario.
  void clear() {
    _generation++;
    _consultation = null;
    _loading = false;
    _saving = false;
    _clearError();
    notifyListeners();
  }

  /// Un doble toque no debe registrar dos veces: los registros no se borran (CON-01).
  Future<bool> _save(Future<ClinicalConsultation> Function() action) async {
    if (_saving) return false;
    final generation = _generation;
    _saving = true;
    _clearError();
    notifyListeners();
    try {
      final consultation = await action();
      if (generation != _generation) return false;
      _consultation = consultation;
      _consultations.upsert(consultation);
      return true;
    } on ClinicalAttentionException catch (error) {
      if (generation == _generation) _setError(error);
      return false;
    } finally {
      if (generation == _generation) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  void _setError(ClinicalAttentionException error) {
    _error = error.code;
    _pendingItems = error.pendingItems;
  }

  void _clearError() {
    _error = null;
    _pendingItems = const [];
  }
}
