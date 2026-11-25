import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/consultation_workspace_store.dart';
import '../../application/patient_directory_store.dart';
import '../../domain/model/clinical_attention_exception.dart';
import '../../domain/model/commands/create_clinical_consultation_command.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';
import '../clinical_error_messages.dart';
import '../widgets/clinical_card.dart';
import '../widgets/clinical_text_field.dart';
import '../widgets/patient_picker.dart';
import '../form_validation.dart';

/// Abre una consulta (US01 Registrar consulta clínica). El veterinario a cargo
/// es el usuario autenticado.
class NewConsultationView extends StatefulWidget {
  const NewConsultationView({
    super.key,
    required this.clinicId,
    required this.onCreated,
    this.petId,
  });

  /// null si el perfil del veterinario aún no está listo.
  final int? clinicId;

  /// Paciente ya elegido, si se llega desde su ficha.
  final int? petId;

  /// Recibe el id de la consulta creada.
  final ValueChanged<int> onCreated;

  @override
  State<NewConsultationView> createState() => _NewConsultationViewState();
}

class _NewConsultationViewState extends State<NewConsultationView> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  PatientSnapshot? _patient;
  int? _consultingRoomId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final clinicId = widget.clinicId;
    if (clinicId == null || !mounted) return;
    context.read<ConsultationWorkspaceStore>().clearError();
    final directory = context.read<PatientDirectoryStore>();
    // Siempre se refresca: pudo registrarse un paciente nuevo en la otra pestaña.
    await directory.loadClinic(clinicId, force: true);
    final petId = widget.petId;
    if (petId == null || _patient != null) return;
    final patient = await directory.loadPatient(petId);
    if (mounted && patient != null) setState(() => _patient = patient);
  }

  Future<void> _submit() async {
    if (!validateAndReveal(_formKey)) return;
    final store = context.read<ConsultationWorkspaceStore>();
    final CreateClinicalConsultationCommand command;
    try {
      command = CreateClinicalConsultationCommand(
        petId: _patient!.petId,
        clinicId: widget.clinicId!,
        consultingRoomId: _consultingRoomId,
        reason: _reason.text,
      );
    } on ClinicalAttentionException catch (error) {
      store.reportError(error);
      return;
    }
    if (await store.create(command) && mounted) widget.onCreated(store.consultation!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nueva consulta')),
      body: _body(),
    );
  }

  Widget _body() {
    if (widget.clinicId == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.badge_outlined,
          title: 'Tu perfil aún no está listo',
          message: 'El administrador de tu clínica debe registrar tu perfil de veterinario desde la web.',
        ),
      );
    }
    final directory = context.watch<PatientDirectoryStore>();
    final store = context.watch<ConsultationWorkspaceStore>();
    if (directory.error != null && directory.patients == null) {
      return Center(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'No se pudieron cargar los datos de tu clínica',
          message: clinicalErrorMessage(directory.error!),
          actionLabel: 'Reintentar',
          onAction: _load,
        ),
      );
    }
    final patients = directory.patients;
    if (patients == null) return const Center(child: CircularProgressIndicator());

    return Form(
      key: _formKey,
      // El error desaparece apenas se corrige.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      // Sin ListView: descarta lo que sale de la pantalla y se perdería lo escrito.
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClinicalCard(
              icon: Icons.pets,
              title: 'Paciente',
              subtitle: 'Mascotas registradas en tu clínica',
              child: PatientPicker(
                patients: patients,
                selected: _patient,
                onSelected: (patient) => setState(() => _patient = patient),
              ),
            ),
            const SizedBox(height: 12),
            ClinicalCard(
              icon: Icons.edit_note,
              title: 'Datos de la consulta',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClinicalTextField(
                    fieldKey: const Key('consultation.reason'),
                    label: 'Motivo de la consulta',
                    controller: _reason,
                    maxLength: ClinicalFieldLimits.reason,
                    requiredMessage: 'Describe el motivo de la consulta.',
                    minLines: 3,
                    maxLines: 6,
                  ),
                  if (directory.consultingRooms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LabeledField(
                      label: 'Consultorio',
                      hint: 'Opcional',
                      child: DropdownButtonFormField<int?>(
                        key: const Key('consultation.room'),
                        initialValue: _consultingRoomId,
                        isExpanded: true,
                        hint: const Text('Sin consultorio'),
                        items: [
                          const DropdownMenuItem(child: Text('Sin consultorio')),
                          for (final room in directory.consultingRooms)
                            DropdownMenuItem(value: room.id, child: Text(room.name)),
                        ],
                        onChanged: (value) => _consultingRoomId = value,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const ClinicalNote(
              'Quedarás como veterinario a cargo. Después registrarás la anamnesis, la evaluación fisiológica, los hallazgos y el diagnóstico.',
              icon: Icons.info_outline,
            ),
            if (store.error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(clinicalErrorMessage(store.error!)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              key: const Key('consultation.submit'),
              label: 'Registrar consulta',
              loading: store.isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
