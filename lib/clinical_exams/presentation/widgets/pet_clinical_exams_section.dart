import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/section_header.dart';
import '../../application/clinical_exams_store.dart';
import 'clinical_exam_tile.dart';
import 'request_exam_sheet.dart';

class PetClinicalExamsSection extends StatefulWidget {
  const PetClinicalExamsSection({super.key, required this.petId, this.canRequest = false});

  final int petId;
  final bool canRequest;

  @override
  State<PetClinicalExamsSection> createState() => _PetClinicalExamsSectionState();
}

class _PetClinicalExamsSectionState extends State<PetClinicalExamsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ClinicalExamsStore>().loadForPet(widget.petId, force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ClinicalExamsStore>();
    final exams = store.examsOf(widget.petId);
    final error = store.errorOf(widget.petId);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    Widget body;
    if (exams == null && error == null) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (error != null) {
      body = Row(
        children: [
          Expanded(child: Text('No se pudieron cargar los exámenes.', style: muted)),
          TextButton(
            onPressed: () => store.loadForPet(widget.petId, force: true),
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (exams!.isEmpty) {
      body = Text('Aún no tiene exámenes clínicos.', style: muted);
    } else {
      body = Column(
        children: [
          for (final exam in exams) ...[
            ClinicalExamTile(
              exam: exam,
              onTap: () => context.push(AppRoutes.clinicalExam(exam.id)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title:
              'Exámenes clínicos'
              '${exams == null || exams.isEmpty ? '' : ' (${exams.length})'}',
          actionLabel: widget.canRequest ? 'Solicitar' : null,
          onAction: () => showRequestExamSheet(context, petId: widget.petId),
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}
