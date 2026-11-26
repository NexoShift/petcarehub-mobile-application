import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/exam_status.dart';

class ExamStatusChip extends StatelessWidget {
  const ExamStatusChip({super.key, required this.status});

  final ExamStatus status;

  static Color colorFor(ExamStatus status) => switch (status) {
    ExamStatus.requested => AppColors.warning,
    ExamStatus.inProcess => AppColors.turquoise,
    ExamStatus.completed => AppColors.success,
    ExamStatus.cancelled => AppColors.textMuted,
  };

  static IconData iconFor(ExamStatus status) => switch (status) {
    ExamStatus.requested => Icons.schedule,
    ExamStatus.inProcess => Icons.hourglass_top,
    ExamStatus.completed => Icons.check_circle_outline,
    ExamStatus.cancelled => Icons.block,
  };

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: status.label, color: colorFor(status), icon: iconFor(status));
}
