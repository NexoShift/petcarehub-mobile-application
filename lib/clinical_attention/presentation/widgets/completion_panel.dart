import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/pending_item.dart';
import '../consultation_phase.dart';
import 'clinical_card.dart';

/// Fase 6: requisitos y resumen antes de cerrar la consulta (MM-19).
class CompletionPanel extends StatelessWidget {
  const CompletionPanel({
    super.key,
    required this.consultation,
    required this.onGoTo,
    this.reportedByServer = const [],
  });

  final ClinicalConsultation consultation;
  final ValueChanged<ConsultationPhase> onGoTo;

  /// Lo que el backend dijo que falta al intentar finalizar.
  final List<PendingItem> reportedByServer;

  static ConsultationPhase phaseOf(PendingItem item) => switch (item) {
    PendingItem.anamnesis => ConsultationPhase.anamnesis,
    PendingItem.physiologicalAssessment => ConsultationPhase.assessment,
    PendingItem.primaryDiagnosis => ConsultationPhase.diagnosis,
  };

  @override
  Widget build(BuildContext context) {
    final pending = {...consultation.pendingItems, ...reportedByServer};
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClinicalCard(
          icon: Icons.checklist,
          title: 'Requisitos para finalizar',
          subtitle: pending.isEmpty ? 'Todo listo' : 'Toca lo pendiente para completarlo',
          child: Column(
            children: [
              for (final item in PendingItem.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    pending.contains(item) ? Icons.radio_button_unchecked : Icons.check_circle,
                    color: pending.contains(item) ? AppColors.warning : AppColors.success,
                  ),
                  title: Text(item.label),
                  subtitle: Text(pending.contains(item) ? 'Pendiente' : 'Listo'),
                  trailing: pending.contains(item) ? const Icon(Icons.chevron_right) : null,
                  onTap: pending.contains(item) ? () => onGoTo(phaseOf(item)) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (consultation.primaryDiagnosis != null) ...[
          ClinicalCard(
            icon: Icons.medical_services_outlined,
            title: 'Diagnóstico principal',
            subtitle: consultation.primaryDiagnosis!.type.label,
            child: Text(
              consultation.primaryDiagnosis!.description,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _Count('Mediciones', consultation.physiologicalAssessments.length),
            const SizedBox(width: 8),
            _Count('Hallazgos', consultation.findings.length),
            const SizedBox(width: 8),
            _Count('Diagnósticos', consultation.currentDiagnoses.length),
          ],
        ),
        const SizedBox(height: 12),
        const ClinicalNote(
          'Al finalizar, la consulta queda como registro clínico de solo lectura en la historia del paciente. El tratamiento y la receta se registran aparte.',
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
