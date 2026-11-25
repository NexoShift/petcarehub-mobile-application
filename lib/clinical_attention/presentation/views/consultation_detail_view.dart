import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../application/consultations_store.dart';
import '../../application/patient_directory_store.dart';
import '../../domain/model/clinical_attention_exception.dart';
import '../clinical_error_messages.dart';
import '../clinical_formatters.dart';
import '../widgets/consultation_record.dart';

/// MM-07 Detalle de una consulta, de solo lectura. La abre el dueño.
///
/// Lee la consulta desde la historia de la mascota, que es el endpoint que la
/// API abre al dueño.
class ConsultationDetailView extends StatefulWidget {
  const ConsultationDetailView({super.key, required this.petId, required this.consultationId});

  final int petId;
  final int consultationId;

  @override
  State<ConsultationDetailView> createState() => _ConsultationDetailViewState();
}

class _ConsultationDetailViewState extends State<ConsultationDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final consultations = context.read<ConsultationsStore>();
    final directory = context.read<PatientDirectoryStore>();
    await consultations.loadForPet(widget.petId, force: force);
    final consultation = consultations.find(
      petId: widget.petId,
      consultationId: widget.consultationId,
    );
    if (consultation != null) await directory.loadStaff(consultation);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationsStore>();
    final directory = context.watch<PatientDirectoryStore>();
    final consultation = store.find(petId: widget.petId, consultationId: widget.consultationId);

    final Widget body;
    if (consultation != null) {
      body = RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ConsultationRecord(
          consultation: consultation,
          patient: directory.patientOf(widget.petId),
          staff: directory.staffOf(consultation.id),
        ),
      );
    } else if (store.errorOf(widget.petId) == null && store.consultationsOf(widget.petId) == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Center(
        child: EmptyState(
          icon: Icons.event_busy,
          title: 'Consulta no disponible',
          message: clinicalErrorMessage(
            store.errorOf(widget.petId) ?? ClinicalAttentionErrorCode.consultationNotFound,
          ),
          actionLabel: 'Reintentar',
          onAction: () => _load(force: true),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(ClinicalFormatters.consultationTitle(widget.consultationId))),
      body: body,
    );
  }
}
