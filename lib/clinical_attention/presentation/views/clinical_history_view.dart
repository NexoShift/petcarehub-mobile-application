import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../application/consultations_store.dart';
import '../../application/patient_directory_store.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/consultation_status.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import '../clinical_error_messages.dart';
import '../widgets/clinical_card.dart';
import '../widgets/consultation_status_chip.dart';
import '../widgets/consultation_tile.dart';

/// MM-06 Historia clínica longitudinal: las consultas de una mascota en una
/// línea de tiempo, de la más reciente a la más antigua.
class ClinicalHistoryView extends StatefulWidget {
  const ClinicalHistoryView({
    super.key,
    required this.petId,
    required this.onOpen,
    this.onRegister,
  });

  final int petId;
  final ValueChanged<ClinicalConsultation> onOpen;

  /// Abrir una consulta nueva. Solo el veterinario.
  final VoidCallback? onRegister;

  @override
  State<ClinicalHistoryView> createState() => _ClinicalHistoryViewState();
}

class _ClinicalHistoryViewState extends State<ClinicalHistoryView> {
  ConsultationStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    context.read<PatientDirectoryStore>().loadPatient(widget.petId);
    await context.read<ConsultationsStore>().loadForPet(widget.petId, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationsStore>();
    final patient = context.watch<PatientDirectoryStore>().patientOf(widget.petId);
    final consultations = store.consultationsOf(widget.petId);
    final error = store.errorOf(widget.petId);

    final Widget body;
    if (error != null) {
      body = Center(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'No se pudo cargar la historia clínica',
          message: clinicalErrorMessage(error),
          actionLabel: 'Reintentar',
          onAction: () => _load(force: true),
        ),
      );
    } else if (consultations == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: _timeline(patient, consultations),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient == null ? 'Historia clínica' : 'Historia clínica de ${patient.name}'),
      ),
      body: body,
      floatingActionButton: widget.onRegister == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('history.newConsultation'),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              onPressed: widget.onRegister,
              icon: const Icon(Icons.add),
              label: const Text('Nueva consulta'),
            ),
    );
  }

  Widget _timeline(PatientSnapshot? patient, List<ClinicalConsultation> consultations) {
    final shown = _filter == null
        ? consultations
        : consultations.where((c) => c.status == _filter).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        if (patient != null) ...[_PatientHeader(patient: patient), const SizedBox(height: 12)],
        _Stats(consultations: consultations),
        const SizedBox(height: 12),
        if (consultations.isEmpty)
          const EmptyState(
            icon: Icons.folder_open,
            title: 'Aún no tiene consultas',
            message: 'Aquí aparecerá cada atención clínica de la mascota.',
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(null, 'Todas', consultations.length),
                for (final status in ConsultationStatus.values)
                  if (consultations.any((c) => c.status == status))
                    _filterChip(
                      status,
                      status.label,
                      consultations.where((c) => c.status == status).length,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay consultas en este estado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ),
          for (final consultation in shown)
            _TimelineEntry(
              consultation: consultation,
              last: consultation == shown.last,
              onTap: () => widget.onOpen(consultation),
            ),
        ],
        const ClinicalNote(
          'Historial clínico permanente: cada consulta queda registrada y no se borra.',
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }

  Widget _filterChip(ConsultationStatus? status, String label, int count) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.patient});

  final PatientSnapshot patient;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProfileAvatar(imageUrl: patient.photoUrl, fallbackIcon: Icons.pets, radius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  [
                    patient.speciesAndBreed,
                    if (patient.birthDate != null) Formatters.age(patient.birthDate!),
                  ].join(' • '),
                  style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.consultations});

  final List<ClinicalConsultation> consultations;

  @override
  Widget build(BuildContext context) {
    final completed = consultations.where((c) => c.status == ConsultationStatus.completed);
    return Row(
      children: [
        _Stat(label: 'Atenciones', value: '${consultations.length}'),
        const SizedBox(width: 8),
        _Stat(label: 'Finalizadas', value: '${completed.length}'),
        const SizedBox(width: 8),
        _Stat(
          label: 'Última',
          value: consultations.isEmpty ? '–' : Formatters.date(consultations.first.date),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.consultation, required this.last, required this.onTap});

  final ClinicalConsultation consultation;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!last)
          const Positioned(
            left: 11,
            top: 24,
            bottom: 0,
            child: VerticalDivider(width: 2, thickness: 2, color: AppColors.border),
          ),
        Positioned(
          left: 0,
          top: 14,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: ConsultationStatusChip.colorFor(consultation.status),
            child: const Icon(Icons.medical_services_outlined, size: 13, color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 36, bottom: 12),
          child: ConsultationTile(consultation: consultation, onTap: onTap),
        ),
      ],
    );
  }
}
