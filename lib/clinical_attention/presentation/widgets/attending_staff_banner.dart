import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/value_objects/attending_staff.dart';

/// "Francisco Mendoza · Médico veterinario actuante · CMVP 9841" (MM-14).
class AttendingStaffBanner extends StatelessWidget {
  const AttendingStaffBanner({super.key, required this.staff});

  final AttendingStaff? staff;

  @override
  Widget build(BuildContext context) {
    final name = staff?.veterinarianName;
    if (name == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.turquoiseSoft,
              child: Icon(Icons.verified_user_outlined, size: 18, color: AppColors.deepBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    ['Médico veterinario actuante', ?staff?.clinicName].join(' • '),
                    style: text.labelSmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (staff?.licenseNumber != null)
              StatusChip(label: 'CMVP ${staff!.licenseNumber}', color: AppColors.deepBlue),
          ],
        ),
      ),
    );
  }
}
