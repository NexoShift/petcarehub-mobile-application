import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/value_objects/consultation_status.dart';

/// Estado de la consulta con su color.
class ConsultationStatusChip extends StatelessWidget {
  const ConsultationStatusChip(this.status, {super.key});

  final ConsultationStatus status;

  static Color colorFor(ConsultationStatus status) => switch (status) {
    ConsultationStatus.completed => AppColors.success,
    ConsultationStatus.inProgress => AppColors.turquoise,
    ConsultationStatus.created => AppColors.warning,
    ConsultationStatus.cancelled => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) => StatusChip(label: status.label, color: colorFor(status));
}
