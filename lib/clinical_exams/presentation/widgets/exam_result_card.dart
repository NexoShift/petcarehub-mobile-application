import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../domain/model/exam_result.dart';

class ExamResultCard extends StatelessWidget {
  const ExamResultCard({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = result.validated ? AppColors.success : AppColors.warning;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  result.validated ? Icons.verified_user_outlined : Icons.pending_outlined,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.validated
                        ? 'Resultado validado'
                              '${result.validatedAt == null ? '' : ' el ${Formatters.date(result.validatedAt!)}'}'
                        : 'Resultado pendiente de validación',
                    style: text.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Fecha del resultado: ${Formatters.date(result.resultDate)}',
                style: text.labelMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          _Block(title: 'Resumen', body: result.summary),
          if (result.values != null) _Block(title: 'Valores', body: result.values!, values: true),
          if (result.interpretation != null)
            _Block(title: 'Interpretación', body: result.interpretation!),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body, this.values = false});

  final String title;
  final String body;
  final bool values;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: values ? AppColors.background : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              body,
              style: text.bodyMedium?.copyWith(
                fontFeatures: values ? const [FontFeature.tabularFigures()] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
