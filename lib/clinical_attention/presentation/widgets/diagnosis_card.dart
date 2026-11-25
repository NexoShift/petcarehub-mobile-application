import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/entities/diagnosis.dart';
import '../../domain/model/value_objects/diagnosis_type.dart';

/// Un diagnóstico (MM-07). [onReevaluate] es null si no se puede reevaluar.
class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({super.key, required this.diagnosis, this.onReevaluate});

  final Diagnosis diagnosis;
  final VoidCallback? onReevaluate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDefinitive = diagnosis.type == DiagnosisType.definitive;
    return AppCard(
      color: diagnosis.isCurrent ? null : AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(
                label: diagnosis.type.label,
                color: isDefinitive ? AppColors.success : AppColors.warning,
                icon: isDefinitive ? Icons.check_circle_outline : Icons.help_outline,
              ),
              if (diagnosis.primary)
                const StatusChip(label: 'Principal', color: AppColors.deepBlue),
              if (!diagnosis.isCurrent)
                StatusChip(label: diagnosis.status.label, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diagnosis.description,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          if (diagnosis.rationale != null) ...[
            const SizedBox(height: 6),
            Text(diagnosis.rationale!, style: text.bodyMedium),
          ],
          if (diagnosis.differentialDiagnoses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Diferenciales', style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
            for (final differential in diagnosis.differentialDiagnoses)
              Text('• $differential', style: text.bodySmall),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.dateTime(diagnosis.diagnosedAt),
                  style: text.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
              if (onReevaluate != null)
                TextButton.icon(
                  key: Key('diagnosis.reevaluate.${diagnosis.id}'),
                  onPressed: onReevaluate,
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const Text('Reevaluar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diagnósticos reemplazados por una reevaluación (CON-01: no se borran).
class SupersededDiagnoses extends StatelessWidget {
  const SupersededDiagnoses({super.key, required this.diagnoses});

  final List<Diagnosis> diagnoses;

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const PageStorageKey('superseded-diagnoses'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(
          'Diagnósticos anteriores (${diagnoses.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
        ),
        children: [
          for (final diagnosis in diagnoses.reversed) ...[
            DiagnosisCard(diagnosis: diagnosis),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
