import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../consultation_phase.dart';

/// Barra de las 6 fases: verde las registradas, resaltada la actual (MM-18).
class PhaseStepper extends StatelessWidget {
  const PhaseStepper({
    super.key,
    required this.consultation,
    required this.current,
    required this.onSelected,
  });

  final ClinicalConsultation consultation;
  final ConsultationPhase current;
  final ValueChanged<ConsultationPhase> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fase ${current.number}: ${current.title}',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Text(
                'Paso ${current.number} de ${ConsultationPhase.values.length}',
                style: text.labelMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final phase in ConsultationPhase.values)
                Expanded(
                  child: _Step(
                    phase: phase,
                    selected: phase == current,
                    done: phase.isDoneIn(consultation),
                    onTap: phase.available ? () => onSelected(phase) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.phase,
    required this.selected,
    required this.done,
    required this.onTap,
  });

  final ConsultationPhase phase;
  final bool selected;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected || done ? AppColors.turquoise : AppColors.border;
    final status = !phase.available
        ? 'próximamente'
        : done
        ? 'registrada'
        : 'pendiente';
    return Tooltip(
      message: phase.available ? phase.shortTitle : '${phase.shortTitle}: próximamente',
      excludeFromSemantics: true,
      child: Semantics(
        button: phase.available,
        enabled: phase.available,
        selected: selected,
        label: 'Fase ${phase.number}, ${phase.shortTitle}, $status',
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          key: Key('phase.${phase.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: done
                        ? const Icon(Icons.check, size: 16, color: AppColors.turquoise)
                        : !phase.available
                        ? const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted)
                        : Text(
                            '${phase.number}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? AppColors.navy : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
