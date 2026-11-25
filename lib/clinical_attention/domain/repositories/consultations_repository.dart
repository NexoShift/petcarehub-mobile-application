import '../model/consultation_summary.dart';

abstract interface class ConsultationsRepository {
  /// Consultas de la mascota, de la más reciente a la más antigua.
  Future<List<ConsultationSummary>> getByPet(int petId);
}
