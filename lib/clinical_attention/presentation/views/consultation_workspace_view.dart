import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/consultation_workspace_store.dart';
import '../../application/patient_directory_store.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/clinical_attention_exception.dart';
import '../../domain/model/commands/cancel_clinical_consultation_command.dart';
import '../../domain/model/entities/diagnosis.dart';
import '../clinical_error_messages.dart';
import '../clinical_formatters.dart';
import '../consultation_phase.dart';
import '../widgets/anamnesis_panel.dart';
import '../widgets/assessment_panel.dart';
import '../widgets/attending_staff_banner.dart';
import '../widgets/cancel_consultation_dialog.dart';
import '../widgets/clinical_card.dart';
import '../widgets/clinical_form_sheet.dart';
import '../widgets/completion_panel.dart';
import '../widgets/consultation_record.dart';
import '../widgets/diagnosis_panel.dart';
import '../widgets/diagnosis_sheets.dart';
import '../widgets/finding_form_sheet.dart';
import '../widgets/findings_section.dart';
import '../widgets/patient_card.dart';
import '../widgets/phase_stepper.dart';

/// Registro de una consulta, fase por fase (MM-14 a MM-19). Una consulta
/// finalizada o cancelada es un registro cerrado y se muestra de solo lectura.
class ConsultationWorkspaceView extends StatefulWidget {
  const ConsultationWorkspaceView({super.key, required this.consultationId});

  final int consultationId;

  @override
  State<ConsultationWorkspaceView> createState() => _ConsultationWorkspaceViewState();
}

class _ConsultationWorkspaceViewState extends State<ConsultationWorkspaceView> {
  final _anamnesisKey = GlobalKey<AnamnesisPanelState>();
  ConsultationPhase _phase = ConsultationPhase.anamnesis;

  /// Fases con datos escritos que aún no se registran.
  final Set<ConsultationPhase> _dirty = {};

  ConsultationWorkspaceStore get _store => context.read<ConsultationWorkspaceStore>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final directory = context.read<PatientDirectoryStore>();
    final store = _store;
    if (!await store.load(widget.consultationId) || !mounted) return;
    final consultation = store.consultation!;
    setState(() {
      _dirty.clear();
      _phase = ConsultationPhase.firstPendingOf(consultation);
    });
    await directory.loadStaff(consultation);
  }

  /// Crea el command, lo envía y avisa. Un command inválido se reporta como error.
  Future<bool> _send<C>(
    C Function() build,
    Future<bool> Function(C command) action,
    String message,
  ) async {
    final C command;
    try {
      command = build();
    } on ClinicalAttentionException catch (error) {
      _store.reportError(error);
      return false;
    }
    return _notify(action(command), message);
  }

  Future<bool> _notify(Future<bool> action, String message) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await action;
    if (done && mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    }
    return done;
  }

  void _markDirty(ConsultationPhase phase) {
    if (_dirty.contains(phase)) return;
    setState(() => _dirty.add(phase));
  }

  void _goTo(ConsultationPhase phase) {
    FocusScope.of(context).unfocus();
    _store.clearError();
    setState(() => _phase = phase);
  }

  Future<void> _start(ClinicalConsultation consultation) =>
      _notify(_store.start(consultation.id), 'Consulta iniciada');

  Future<void> _cancel(ClinicalConsultation consultation) async {
    final reason = await showCancelConsultationDialog(context);
    if (reason == null || !mounted) return;
    await _send(
      () => CancelClinicalConsultationCommand(consultationId: consultation.id, reason: reason),
      _store.cancel,
      'Consulta cancelada',
    );
    if (mounted) setState(_dirty.clear);
  }

  Future<void> _complete(ClinicalConsultation consultation) async {
    final confirmed = await _confirm(
      title: 'Finalizar consulta',
      message: _dirty.isEmpty
          ? 'Quedará como registro clínico de solo lectura y no se podrá modificar.'
          : 'Hay datos escritos que aún no registraste y se perderán. La consulta quedará de solo lectura.',
      action: 'Finalizar',
    );
    if (!confirmed || !mounted) return;
    if (await _notify(_store.complete(consultation.id), 'Consulta finalizada') && mounted) {
      setState(_dirty.clear);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            key: const Key('dialog.confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _confirmExit() async {
    final navigator = Navigator.of(context);
    final exit = await _confirm(
      title: '¿Salir de la consulta?',
      message: 'Hay datos escritos que aún no registraste y se perderán.',
      action: 'Salir',
    );
    if (!exit || !mounted) return;
    setState(_dirty.clear);
    // El PopScope se actualiza en el siguiente frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) navigator.maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationWorkspaceStore>();
    final consultation = store.consultation?.id == widget.consultationId
        ? store.consultation
        : null;

    return PopScope(
      canPop: _dirty.isEmpty && !store.isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !store.isSaving) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(ClinicalFormatters.consultationTitle(widget.consultationId)),
          actions: [
            if (consultation?.canCancel ?? false)
              PopupMenuButton<void>(
                key: const Key('workspace.menu'),
                tooltip: 'Más opciones',
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: const Key('workspace.cancel'),
                    enabled: !store.isSaving,
                    onTap: () => _cancel(consultation!),
                    child: const Text('Cancelar consulta'),
                  ),
                ],
              ),
          ],
        ),
        body: consultation == null ? _placeholder(store) : _body(store, consultation),
        bottomNavigationBar: consultation != null && consultation.isInProgress
            ? _bottomBar(store, consultation)
            : null,
      ),
    );
  }

  Widget _placeholder(ConsultationWorkspaceStore store) {
    final error = store.error;
    if (error == null || store.isLoading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: EmptyState(
        icon: Icons.event_busy,
        title: 'Consulta no disponible',
        message: clinicalErrorMessage(error),
        actionLabel: 'Reintentar',
        onAction: _load,
      ),
    );
  }

  Widget _body(ConsultationWorkspaceStore store, ClinicalConsultation consultation) {
    final directory = context.watch<PatientDirectoryStore>();
    final patient = directory.patientOf(consultation.petId);
    final staff = directory.staffOf(consultation.id);

    if (consultation.isClosed) {
      return ConsultationRecord(consultation: consultation, patient: patient, staff: staff);
    }

    final header = [
      AttendingStaffBanner(staff: staff),
      PatientCard(consultation: consultation, patient: patient, staff: staff),
      const SizedBox(height: 12),
    ];

    if (consultation.canStart) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...header,
          ClinicalCard(
            icon: Icons.event_available,
            title: 'Consulta registrada',
            subtitle: 'Iníciala para registrar la anamnesis, las constantes, los hallazgos y el diagnóstico.',
            child: Text(consultation.reason),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(clinicalErrorMessage(store.error!)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            key: const Key('workspace.start'),
            label: 'Iniciar consulta',
            loading: store.isSaving,
            onPressed: () => _start(consultation),
          ),
        ],
      );
    }

    // Sin ListView: descarta lo que sale de la pantalla y se perdería lo escrito.
    Widget phase(List<Widget> children) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...header, ...children],
      ),
    );

    return Column(
      children: [
        PhaseStepper(consultation: consultation, current: _phase, onSelected: _goTo),
        const Divider(height: 1, color: AppColors.border),
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(clinicalErrorMessage(store.error!)),
          ),
        Expanded(
          // IndexedStack conserva lo escrito al cambiar de fase: no hay borradores en la API.
          child: IndexedStack(
            index: ConsultationPhase.availablePhases.indexOf(_phase),
            children: [
              phase([
                AnamnesisPanel(
                  key: _anamnesisKey,
                  consultation: consultation,
                  onDirty: () => _markDirty(ConsultationPhase.anamnesis),
                  onSubmit: (build) async {
                    final done = await _send(
                      build,
                      _store.registerAnamnesis,
                      'Anamnesis registrada',
                    );
                    if (!done || !mounted) return;
                    _dirty.remove(ConsultationPhase.anamnesis);
                    _goTo(ConsultationPhase.assessment);
                  },
                ),
              ]),
              phase([
                AssessmentPanel(
                  consultation: consultation,
                  saving: store.isSaving,
                  onDirty: () => _markDirty(ConsultationPhase.assessment),
                  onSubmit: (build) async {
                    final done = await _send(
                      build,
                      _store.registerPhysiologicalAssessment,
                      'Medición registrada',
                    );
                    if (done && mounted) {
                      setState(() => _dirty.remove(ConsultationPhase.assessment));
                    }
                  },
                ),
                const SizedBox(height: 12),
                FindingsSection(
                  findings: consultation.findings,
                  onAdd: store.isSaving ? null : () => _addFinding(consultation),
                ),
              ]),
              phase([
                DiagnosisPanel(
                  consultation: consultation,
                  saving: store.isSaving,
                  onDirty: () => _markDirty(ConsultationPhase.diagnosis),
                  onSubmit: (build) async {
                    final done = await _send(
                      build,
                      _store.registerDiagnosis,
                      'Diagnóstico registrado',
                    );
                    if (done && mounted) {
                      setState(() => _dirty.remove(ConsultationPhase.diagnosis));
                    }
                  },
                  onAddSecondary: () => _addSecondaryDiagnosis(consultation),
                  onReevaluate: (diagnosis) => _reevaluate(consultation, diagnosis),
                ),
              ]),
              phase([
                CompletionPanel(
                  consultation: consultation,
                  reportedByServer: store.pendingItems,
                  onGoTo: _goTo,
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addFinding(ClinicalConsultation consultation) => showClinicalFormSheet(
    context,
    builder: (_) => FindingFormSheet(
      consultationId: consultation.id,
      onSubmit: (build) => _send(build, _store.addClinicalFinding, 'Hallazgo agregado'),
    ),
  );

  Future<void> _addSecondaryDiagnosis(ClinicalConsultation consultation) => showClinicalFormSheet(
    context,
    builder: (_) => SecondaryDiagnosisSheet(
      consultationId: consultation.id,
      onSubmit: (build) => _send(build, _store.registerDiagnosis, 'Diagnóstico registrado'),
    ),
  );

  Future<void> _reevaluate(ClinicalConsultation consultation, Diagnosis diagnosis) =>
      showClinicalFormSheet(
        context,
        builder: (_) => ReevaluationSheet(
          consultationId: consultation.id,
          diagnosis: diagnosis,
          onSubmit: (build) => _send(build, _store.reevaluateDiagnosis, 'Diagnóstico reevaluado'),
        ),
      );

  Widget _bottomBar(ConsultationWorkspaceStore store, ClinicalConsultation consultation) {
    final next = _phase.next;
    final previous = _phase.previous;
    final (label, onPressed) = switch (_phase) {
      ConsultationPhase.anamnesis when consultation.canRegisterAnamnesis => (
        'Registrar anamnesis',
        () => _anamnesisKey.currentState?.submit(),
      ),
      ConsultationPhase.completion => (
        'Finalizar consulta',
        consultation.canComplete ? () => _complete(consultation) : null,
      ),
      _ => ('Siguiente: ${next!.shortTitle}', () => _goTo(next)),
    };
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (previous != null) ...[
                IconButton.filledTonal(
                  key: const Key('workspace.previous'),
                  tooltip: 'Anterior: ${previous.shortTitle}',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _goTo(previous),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: PrimaryButton(
                  key: const Key('workspace.next'),
                  label: label,
                  loading: store.isSaving,
                  showArrow: _phase != ConsultationPhase.completion,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
