import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../domain/model/clinical_exam.dart';
import '../../domain/model/exam_type.dart';
import 'exam_status_chip.dart';

class ClinicalExamTile extends StatelessWidget {
  const ClinicalExamTile({super.key, required this.exam, this.onTap});

  final ClinicalExam exam;
  final VoidCallback? onTap;

  static IconData iconFor(ExamType type) => switch (type) {
    ExamType.radiography => Icons.radio_button_checked,
    ExamType.ultrasound => Icons.monitor_heart_outlined,
    ExamType.laboratory => Icons.science_outlined,
    ExamType.other => Icons.assignment_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final files = exam.files.length;
    return AppCard(
      key: Key('exam-${exam.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.turquoiseSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconFor(exam.type), color: AppColors.deepBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam.type.label,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    ExamStatusChip(status: exam.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicitado el ${Formatters.date(exam.requestedAt)}',
                  style: text.labelMedium?.copyWith(color: AppColors.textMuted),
                ),
                if (exam.indication != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    exam.indication!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
                if (exam.hasValidatedResult || files > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (exam.hasValidatedResult)
                        const _Meta(icon: Icons.verified_outlined, label: 'Resultado validado'),
                      if (files > 0)
                        _Meta(
                          icon: Icons.attach_file,
                          label: files == 1 ? '1 archivo' : '$files archivos',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
