import '../domain/model/aggregates/clinical_consultation.dart';

/// Fases del registro de una consulta (MM-14 a MM-19).
///
/// Las fases 3 (imágenes) y 4 (asistente) son de AI Assistance, que aún no está
/// en la app móvil: se muestran pero no se pueden abrir.
enum ConsultationPhase {
  anamnesis('Anamnesis', 'Anamnesis e historial del cuadro'),
  assessment('Evaluación', 'Evaluación fisiológica y hallazgos'),
  images('Imágenes', 'Captura de imágenes clínicas', available: false),
  assistant('Asistente', 'Asistencia clínica con IA', available: false),
  diagnosis('Diagnóstico', 'Diagnóstico'),
  completion('Finalización', 'Finalización de la consulta');

  const ConsultationPhase(this.shortTitle, this.title, {this.available = true});

  final String shortTitle;
  final String title;
  final bool available;

  int get number => index + 1;

  static final List<ConsultationPhase> availablePhases = values.where((p) => p.available).toList();

  ConsultationPhase? get next => _sibling(1);
  ConsultationPhase? get previous => _sibling(-1);

  ConsultationPhase? _sibling(int step) {
    final index = availablePhases.indexOf(this) + step;
    return index < 0 ? null : availablePhases.elementAtOrNull(index);
  }

  /// Primera fase sin datos, para que el veterinario continúe donde se quedó.
  static ConsultationPhase firstPendingOf(ClinicalConsultation consultation) {
    if (consultation.anamnesis == null) return anamnesis;
    if (consultation.physiologicalAssessments.isEmpty) return assessment;
    if (consultation.primaryDiagnosis == null) return diagnosis;
    return completion;
  }

  bool isDoneIn(ClinicalConsultation consultation) => switch (this) {
    anamnesis => consultation.anamnesis != null,
    assessment => consultation.physiologicalAssessments.isNotEmpty,
    diagnosis => consultation.primaryDiagnosis != null,
    images || assistant || completion => false,
  };
}
