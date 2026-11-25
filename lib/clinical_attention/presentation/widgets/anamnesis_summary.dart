import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/entities/anamnesis.dart';
import 'clinical_card.dart';

/// Anamnesis de solo lectura.
class AnamnesisSummary extends StatelessWidget {
  const AnamnesisSummary({super.key, required this.anamnesis});

  final Anamnesis anamnesis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '“${anamnesis.chiefComplaint}”',
            style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        ClinicalFact(label: 'Tiempo de evolución', value: anamnesis.evolutionTime),
        if (anamnesis.symptoms.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Síntomas', style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final symptom in anamnesis.symptoms)
                StatusChip(label: symptom, color: AppColors.deepBlue),
            ],
          ),
        ],
        ClinicalFact(label: 'Tratamientos previos', value: anamnesis.previousTreatments),
        ClinicalFact(label: 'Alimentación', value: anamnesis.diet),
        ClinicalFact(label: 'Comportamiento', value: anamnesis.behavior),
        ClinicalFact(label: 'Observaciones del tutor', value: anamnesis.ownerObservations),
      ],
    );
  }
}
