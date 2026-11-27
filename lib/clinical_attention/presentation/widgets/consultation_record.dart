import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/attending_staff.dart';
import '../../domain/model/value_objects/consultation_status.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import 'anamnesis_summary.dart';
import 'assessment_summary.dart';
import 'clinical_card.dart';
import 'consultation_status_chip.dart';
import 'diagnosis_card.dart';
import 'findings_section.dart';

/// Consulta completa de solo lectura (MM-07). La usan el dueño y el veterinario.
class ConsultationRecord extends StatelessWidget {
  const ConsultationRecord({super.key, required this.consultation, this.patient, this.staff});

  final ClinicalConsultation consultation;
  final PatientSnapshot? patient;
  final AttendingStaff? staff;

  @override
  Widget build(BuildContext context) {
    final assessments = consultation.physiologicalAssessments;
    const gap = SizedBox(height: 12);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _Header(consultation: consultation, patient: patient),
        gap,
        _Verification(consultation: consultation, staff: staff),
        gap,
        ClinicalCard(
          icon: Icons.record_voice_over_outlined,
          title: 'Motivo de consulta y anamnesis',
          child: consultation.anamnesis == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consultation.reason),
                    const SizedBox(height: 8),
                    Text(
                      consultation.isClosed
                          ? 'No se registró anamnesis.'
                          : 'Aún no se registra la anamnesis.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                )
              : AnamnesisSummary(anamnesis: consultation.anamnesis!),
        ),
        if (assessments.isNotEmpty) ...[
          gap,
          ClinicalCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Constantes fisiológicas',
            subtitle: assessments.length > 1 ? '${assessments.length} mediciones' : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, assessment) in assessments.reversed.indexed) ...[
                  if (index > 0) const Divider(height: 24),
                  AssessmentSummary(assessment: assessment),
                ],
              ],
            ),
          ),
        ],
        if (consultation.findings.isNotEmpty) ...[
          gap,
          FindingsSection(findings: consultation.findings),
        ],
        for (final diagnosis in consultation.currentDiagnoses) ...[
          gap,
          DiagnosisCard(diagnosis: diagnosis),
        ],
        SupersededDiagnoses(diagnoses: consultation.supersededDiagnoses),
        if (consultation.isClosed) ...[
          gap,
          const ClinicalNote(
            'Registro clínico permanente: se puede consultar, pero no modificar ni borrar.',
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.consultation, required this.patient});

  final ClinicalConsultation consultation;
  final PatientSnapshot? patient;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppColors.textMuted);
    return AppCard(
      child: Row(
        children: [
          ProfileAvatar(imageUrl: patient?.photoUrl, fallbackIcon: Icons.pets, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient?.name ?? 'Mascota N.° ${consultation.petId}',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                if (patient != null) Text(patient!.speciesAndBreed, style: muted),
                Text(Formatters.dateTime(consultation.date), style: muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConsultationStatusChip(consultation.status),
        ],
      ),
    );
  }
}

class _Verification extends StatelessWidget {
  const _Verification({required this.consultation, required this.staff});

  final ClinicalConsultation consultation;
  final AttendingStaff? staff;

  @override
  Widget build(BuildContext context) {
    final vet = staff?.veterinarianName;
    final license = staff?.licenseNumber;
    final by = [
      if (vet != null) 'por $vet${license == null ? '' : ' (CMVP $license)'}',
      if (staff?.clinicName != null) 'en ${staff!.clinicName}',
    ].join(' ');
    final suffix = by.isEmpty ? '' : ' $by';
    return switch (consultation.status) {
      ConsultationStatus.completed => ClinicalNote(
        'Atención finalizada$suffix el ${Formatters.dateTime(consultation.date)}.',
        icon: Icons.verified,
      ),
      ConsultationStatus.cancelled => ClinicalNote(
        'Consulta cancelada el ${Formatters.dateTime(consultation.date)}. '
        'Motivo: ${consultation.cancellationReason ?? 'no indicado'}.',
        icon: Icons.event_busy,
      ),
      ConsultationStatus.inProgress => ClinicalNote(
        'Atención en curso$suffix. El registro aún puede cambiar.',
        icon: Icons.hourglass_bottom,
      ),
      ConsultationStatus.created => ClinicalNote(
        'Consulta registrada$suffix. Aún no se inicia la atención.',
        icon: Icons.event_available,
      ),
    };
  }
}
