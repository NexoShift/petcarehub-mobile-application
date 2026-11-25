import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/consultation_status.dart';
import '../../domain/model/consultation_summary.dart';

/// Tarjeta de una consulta: fecha, estado, motivo y diagnóstico principal.
class ConsultationTile extends StatelessWidget {
  const ConsultationTile({super.key, required this.consultation});

  final ConsultationSummary consultation;

  static Color colorFor(ConsultationStatus status) => switch (status) {
        ConsultationStatus.completed => AppColors.success,
        ConsultationStatus.inProgress => AppColors.turquoise,
        ConsultationStatus.created => AppColors.warning,
        ConsultationStatus.cancelled => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Formatters.date(consultation.date),
                  style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              StatusChip(
                label: consultation.status.label,
                color: colorFor(consultation.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consultation.reason.isEmpty ? 'Consulta clínica' : consultation.reason,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          if (consultation.mainDiagnosis != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text.rich(
                TextSpan(
                  style: text.bodySmall,
                  children: [
                    const TextSpan(
                      text: 'Diagnóstico: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: consultation.mainDiagnosis),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
