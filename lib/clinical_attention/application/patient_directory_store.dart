import 'package:flutter/foundation.dart';

import '../domain/model/aggregates/clinical_consultation.dart';
import '../domain/model/clinical_attention_exception.dart';
import '../domain/model/value_objects/attending_staff.dart';
import '../domain/model/value_objects/consulting_room_snapshot.dart';
import '../domain/model/value_objects/patient_snapshot.dart';
import 'outbound_services/external_profiles_service.dart';

/// Pacientes, consultorios y nombres que vienen de Profiles a través del ACL.
class PatientDirectoryStore extends ChangeNotifier {
  PatientDirectoryStore({required this._profiles});

  final ExternalProfilesService _profiles;

  List<PatientSnapshot>? _patients;
  List<ConsultingRoomSnapshot> _rooms = const [];
  ClinicalAttentionErrorCode? _error;
  int? _loadedClinicId;
  bool _loading = false;
  final Map<int, PatientSnapshot> _byPet = {};
  final Map<int, AttendingStaff> _staffByConsultation = {};
  int _generation = 0;

  /// null mientras no se hayan cargado.
  List<PatientSnapshot>? get patients => _patients;
  List<ConsultingRoomSnapshot> get consultingRooms => _rooms;
  ClinicalAttentionErrorCode? get error => _error;

  PatientSnapshot? patientOf(int petId) => _byPet[petId];
  AttendingStaff? staffOf(int consultationId) => _staffByConsultation[consultationId];

  List<PatientSnapshot> search(String query) =>
      (_patients ?? const <PatientSnapshot>[]).where((p) => p.matches(query)).toList();

  /// Pacientes y consultorios de la clínica del veterinario.
  Future<void> loadClinic(int clinicId, {bool force = false}) async {
    if (_loading || (!force && _loadedClinicId == clinicId)) return;
    final generation = _generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Los consultorios son opcionales y nunca fallan: se piden en paralelo.
      final pendingRooms = _profiles.getActiveConsultingRooms(clinicId);
      final patients = await _profiles.getClinicPatients(clinicId);
      final rooms = await pendingRooms;
      if (generation != _generation) return;
      _patients = patients;
      _rooms = rooms;
      _loadedClinicId = clinicId;
      for (final patient in patients) {
        _byPet[patient.petId] = patient;
      }
    } on ClinicalAttentionException catch (error) {
      if (generation == _generation) _error = error.code;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<PatientSnapshot?> loadPatient(int petId) async {
    final cached = _byPet[petId];
    if (cached != null) return cached;
    final generation = _generation;
    try {
      final patient = await _profiles.getPatient(petId);
      if (generation != _generation) return null;
      _byPet[petId] = patient;
      notifyListeners();
      return patient;
    } on ClinicalAttentionException {
      // La consulta se muestra igual, sin la ficha de la mascota.
      return null;
    }
  }

  /// Nombres de quienes participaron en la consulta.
  Future<void> loadStaff(ClinicalConsultation consultation) async {
    // Vacío = Profiles no respondió la vez anterior: se vuelve a intentar.
    if (_staffByConsultation[consultation.id]?.isEmpty == false) return;
    final generation = _generation;
    final patient = await loadPatient(consultation.petId);
    final staff = await _profiles.getAttendingStaff(consultation, ownerId: patient?.ownerId);
    if (generation != _generation) return;
    _staffByConsultation[consultation.id] = staff;
    notifyListeners();
  }

  /// Al cerrar sesión no deben quedar datos de otro usuario.
  void clear() {
    _generation++;
    _patients = null;
    _rooms = const [];
    _error = null;
    _loadedClinicId = null;
    _loading = false;
    _byPet.clear();
    _staffByConsultation.clear();
    notifyListeners();
  }
}
