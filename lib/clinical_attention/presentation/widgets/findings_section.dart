import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/entities/clinical_finding.dart';
import '../../domain/model/value_objects/finding_severity.dart';
import 'clinical_action_button.dart';
import 'clinical_card.dart';

/// Hallazgos por sistema del cuerpo. [onAdd] es null en los registros cerrados.
class FindingsSection extends StatelessWidget {
  const FindingsSection({super.key, required this.findings, this.onAdd});

  final List<ClinicalFinding> findings;
  final VoidCallback? onAdd;

  static Color colorFor(FindingSeverity severity) => switch (severity) {
    FindingSeverity.mild => AppColors.success,
    FindingSeverity.moderate => AppColors.warning,
    FindingSeverity.severe => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClinicalCard(
      icon: Icons.search,
      title: 'Hallazgos clínicos',
      subtitle: 'Lo observado en cada sistema del cuerpo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (findings.isEmpty)
            Text(
              'Aún no hay hallazgos.',
              style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          for (final finding in findings)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          finding.bodySystem.label,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (finding.severity != null)
                        StatusChip(
                          label: finding.severity!.label,
                          color: colorFor(finding.severity!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(finding.description, style: text.bodyMedium),
                ],
              ),
            ),
          if (onAdd != null) ...[
            const SizedBox(height: 8),
            ClinicalActionButton(
              key: const Key('findings.add'),
              label: 'Agregar hallazgo',
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}
