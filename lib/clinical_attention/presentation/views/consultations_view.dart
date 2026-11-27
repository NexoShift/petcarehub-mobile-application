import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../application/consultations_store.dart';
import '../../application/patient_directory_store.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import '../clinical_error_messages.dart';
import '../widgets/consultation_tile.dart';

/// Pestaña "Consultas" del veterinario: elige un paciente de la clínica y ve sus
/// consultas. La API lista por mascota, así que se pide solo la elegida.
class ConsultationsView extends StatefulWidget {
  const ConsultationsView({
    super.key,
    required this.clinicId,
    required this.onOpen,
    required this.onRegister,
  });

  /// null si el perfil del veterinario aún no está listo.
  final int? clinicId;
  final ValueChanged<ClinicalConsultation> onOpen;

  /// Recibe la mascota elegida, si hay una.
  final ValueChanged<int?> onRegister;

  @override
  State<ConsultationsView> createState() => _ConsultationsViewState();
}

class _ConsultationsViewState extends State<ConsultationsView> {
  String _query = '';
  int? _selectedPetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final clinicId = widget.clinicId;
    if (clinicId == null || !mounted) return;
    final directory = context.read<PatientDirectoryStore>();
    final consultations = context.read<ConsultationsStore>();
    await directory.loadClinic(clinicId, force: force);
    if (!mounted) return;
    final petId = _selectedPetId ?? directory.patients?.firstOrNull?.petId;
    if (petId == null) return;
    setState(() => _selectedPetId = petId);
    await consultations.loadForPet(petId, force: force);
  }

  void _select(int petId) {
    setState(() => _selectedPetId = petId);
    context.read<ConsultationsStore>().loadForPet(petId);
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<PatientDirectoryStore>();
    final hasPatients = directory.patients?.isNotEmpty ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(hasPatients: hasPatients),
            Expanded(child: _body(directory)),
          ],
        ),
      ),
      floatingActionButton: hasPatients
          ? FloatingActionButton.extended(
              key: const Key('consultations.new'),
              heroTag: 'consultations.new',
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              onPressed: () => widget.onRegister(_selectedPetId),
              icon: const Icon(Icons.add),
              label: const Text('Nueva consulta'),
            )
          : null,
    );
  }

  Widget _header({required bool hasPatients}) {
    final text = Theme.of(context).textTheme;
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Consultas clínicas',
            style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(
            'Elige un paciente para ver sus consultas',
            style: text.bodySmall?.copyWith(color: AppColors.turquoise),
          ),
          if (hasPatients) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('consultations.search'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                fillColor: Colors.white,
                hintText: 'Buscar paciente, raza o ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(PatientDirectoryStore directory) {
    if (widget.clinicId == null) {
      return const SingleChildScrollView(
        child: EmptyState(
          icon: Icons.badge_outlined,
          title: 'Tu perfil aún no está listo',
          message: 'El administrador de tu clínica debe registrar tu perfil de veterinario desde la web.',
        ),
      );
    }
    final error = directory.error;
    if (error != null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'No se pudieron cargar los pacientes',
          message: clinicalErrorMessage(error),
          actionLabel: 'Reintentar',
          onAction: () => _load(force: true),
        ),
      );
    }
    final patients = directory.patients;
    if (patients == null) return const Center(child: CircularProgressIndicator());

    final found = directory.search(_query);
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (patients.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Tu clínica aún no tiene pacientes',
              message: 'Regístralos desde la pestaña Pacientes.',
            )
          else if (found.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ningún paciente coincide con la búsqueda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final patient in found)
                    _PatientOption(
                      patient: patient,
                      selected: patient.petId == _selectedPetId,
                      onTap: () => _select(patient.petId),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (found.any((p) => p.petId == _selectedPetId)) ..._consultations(_selectedPetId!),
          ],
        ],
      ),
    );
  }

  List<Widget> _consultations(int petId) {
    final store = context.watch<ConsultationsStore>();
    final error = store.errorOf(petId);
    final consultations = store.consultationsOf(petId);
    if (error != null) {
      return [
        EmptyState(
          icon: Icons.wifi_off,
          title: 'No se pudieron cargar las consultas',
          message: clinicalErrorMessage(error),
          actionLabel: 'Reintentar',
          onAction: () => store.loadForPet(petId, force: true),
        ),
      ];
    }
    if (consultations == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (consultations.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.folder_open,
          title: 'Aún no tiene consultas',
          message: 'Registra la primera con el botón Nueva consulta.',
        ),
      ];
    }
    return [
      for (final consultation in consultations) ...[
        ConsultationTile(consultation: consultation, onTap: () => widget.onOpen(consultation)),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _PatientOption extends StatelessWidget {
  const _PatientOption({required this.patient, required this.selected, required this.onTap});

  final PatientSnapshot patient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.turquoise : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ProfileAvatar(imageUrl: patient.photoUrl, fallbackIcon: Icons.pets, radius: 24),
                  const SizedBox(height: 6),
                  Text(
                    patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    patient.species,
                    style: text.labelSmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
