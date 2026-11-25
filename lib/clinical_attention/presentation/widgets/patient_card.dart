import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/attending_staff.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import '../clinical_formatters.dart';

/// Tarjeta azul del paciente en el registro de la consulta (MM-14).
class PatientCard extends StatelessWidget {
  const PatientCard({super.key, required this.consultation, this.patient, this.staff});

  final ClinicalConsultation consultation;
  final PatientSnapshot? patient;
  final AttendingStaff? staff;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weight = consultation.latestAssessment?.vitalSigns.weightKg;
    final tags = [
      if (patient?.birthDate != null) Formatters.age(patient!.birthDate!),
      if (weight != null) '${ClinicalFormatters.decimal(weight)} kg',
      ?staff?.consultingRoomName,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(imageUrl: patient?.photoUrl, fallbackIcon: Icons.pets, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?.name ?? 'Mascota N.° ${consultation.petId}',
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (patient != null) ...[
                      Text(
                        patient!.speciesAndBreed,
                        style: text.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        patient!.code,
                        style: text.labelSmall?.copyWith(color: AppColors.turquoise),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: text.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (staff?.ownerName != null)
                _Line(icon: Icons.person_outline, label: 'Tutor: ${staff!.ownerName}'),
              _Line(
                icon: Icons.event_outlined,
                label: Formatters.dateTime(consultation.startedAt ?? consultation.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
