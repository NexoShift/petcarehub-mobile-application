import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/entities/physiological_assessment.dart';
import '../clinical_formatters.dart';
import 'clinical_card.dart';

/// Una medición de solo lectura: constantes en cuadros y el resto debajo (MM-07).
class AssessmentSummary extends StatelessWidget {
  const AssessmentSummary({super.key, required this.assessment});

  final PhysiologicalAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final vitals = assessment.vitalSigns;
    final tiles = [
      _VitalTile('Peso', ClinicalFormatters.decimal(vitals.weightKg), 'kg'),
      _VitalTile('Temperatura', ClinicalFormatters.decimal(vitals.temperatureCelsius), '°C'),
      _VitalTile('Frec. cardíaca', '${vitals.heartRateBpm}', 'lpm'),
      _VitalTile('Frec. respiratoria', '${vitals.respiratoryRateBpm}', 'rpm'),
    ];
    final details = [
      if (assessment.bodyConditionScore != null)
        'Condición corporal: ${assessment.bodyConditionScore}/9',
      if (assessment.hydrationStatus != null) 'Hidratación: ${assessment.hydrationStatus!.label}',
      if (assessment.mucousMembranes != null) 'Mucosas: ${assessment.mucousMembranes}',
      if (assessment.capillaryRefillTimeSeconds != null)
        'Llenado capilar: ${ClinicalFormatters.decimal(assessment.capillaryRefillTimeSeconds!)} s',
    ];
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
            );
          },
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final detail in details) Text(detail, style: muted),
        ],
        ClinicalFact(label: 'Observaciones', value: assessment.observations),
        const SizedBox(height: 6),
        Text('Registrada el ${Formatters.dateTime(assessment.recordedAt)}', style: muted),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile(this.label, this.value, this.unit);

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(text: ' $unit', style: text.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
