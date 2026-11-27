import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import 'consultation_status_chip.dart';

/// Tarjeta de una consulta: fecha, estado, motivo y diagnóstico principal.
class ConsultationTile extends StatelessWidget {
  const ConsultationTile({super.key, required this.consultation, this.onTap});

  final ClinicalConsultation consultation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
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
              ConsultationStatusChip(consultation.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consultation.reason.isEmpty ? 'Consulta clínica' : consultation.reason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
          if (onTap != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Text(
                    consultation.isInProgress ? 'Ver consulta en curso' : 'Ver detalle de consulta',
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.navy),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
