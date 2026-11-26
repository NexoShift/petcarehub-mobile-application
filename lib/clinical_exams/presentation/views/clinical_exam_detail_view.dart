import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import '../../../shared/domain/api_error.dart';
import '../../../shared/infrastructure/image_picker_service.dart';
import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/image_source_sheet.dart';
import '../../../shared/presentation/widgets/section_header.dart';
import '../../application/clinical_exams_store.dart';
import '../../domain/model/clinical_exam.dart';
import '../widgets/cancel_exam_dialog.dart';
import '../widgets/clinical_exam_tile.dart';
import '../widgets/clinical_file_tile.dart';
import '../widgets/exam_result_card.dart';
import '../widgets/exam_result_sheet.dart';
import '../widgets/exam_status_chip.dart';

/// Exam detail for the owner (read only) and for the veterinarian, who also moves it through
/// its states: start, register and validate the result, attach photos, complete or cancel.
class ClinicalExamDetailView extends StatefulWidget {
  const ClinicalExamDetailView({super.key, required this.examId});

  final int examId;

  @override
  State<ClinicalExamDetailView> createState() => _ClinicalExamDetailViewState();
}

class _ClinicalExamDetailViewState extends State<ClinicalExamDetailView> {
  ClinicalExam? _exam;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _exam = context.read<ClinicalExamsStore>().cached(widget.examId);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final exam = await context.read<ClinicalExamsStore>().fetch(widget.examId);
      if (mounted) setState(() => _exam = exam);
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _run(
    Future<ClinicalExam> Function(ClinicalExamsStore store) action,
    String done,
  ) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final exam = await action(context.read<ClinicalExamsStore>());
      if (!mounted) return;
      setState(() => _exam = exam);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerResult(ClinicalExam exam) async {
    await showExamResultSheet(context, examId: exam.id);
    if (!mounted) return;
    setState(() => _exam = context.read<ClinicalExamsStore>().cached(exam.id) ?? _exam);
  }

  Future<void> _cancel(ClinicalExam exam) async {
    final reason = await showCancelExamDialog(context);
    if (reason == null || !mounted) return;
    await _run((store) => store.cancel(exam.id, reason), 'Examen cancelado');
  }

  Future<void> _attachPhoto(ClinicalExam exam) async {
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final image = await context.read<ImagePickerService>().pick(source);
    if (image == null || !mounted) return;
    if (!image.isAllowedType || image.bytes.lengthInBytes > ClinicalExam.maxFileBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se aceptan fotos JPG, PNG o WEBP de hasta 10 MB.')),
      );
      return;
    }
    await _run((store) => store.uploadFile(exam, image), 'Foto adjuntada');
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    final isVet = context.watch<IamStore>().session?.isVeterinarian ?? false;

    Widget body;
    if (exam == null && _error != null) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: 'No se pudo cargar el examen',
        message: _error,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    } else if (exam == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Summary(exam: exam),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Resultado'),
            const SizedBox(height: 8),
            if (exam.result != null)
              ExamResultCard(result: exam.result!)
            else
              _Hint(
                isVet
                    ? 'Aún no se registra el resultado.'
                    : 'El resultado aparecerá aquí cuando el veterinario lo valide.',
              ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Archivos${exam.files.isEmpty ? '' : ' (${exam.files.length})'}',
              actionLabel: isVet && exam.canAttachFiles && !_busy ? 'Adjuntar foto' : null,
              onAction: () => _attachPhoto(exam),
            ),
            const SizedBox(height: 8),
            if (exam.files.isEmpty)
              const _Hint('No hay archivos adjuntos.')
            else
              for (final file in exam.files) ...[
                ClinicalFileTile(key: Key('file-${file.id}'), examId: exam.id, file: file),
                const SizedBox(height: 8),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Examen clínico')),
      body: body,
      bottomNavigationBar: exam == null || !isVet ? null : _actions(exam),
    );
  }

  Widget? _actions(ClinicalExam exam) {
    final ({String label, IconData icon, VoidCallback onPressed})? main = switch (exam) {
      _ when exam.canStart => (
        label: 'Iniciar examen',
        icon: Icons.play_arrow,
        onPressed: () => _run((s) => s.start(exam.id), 'Examen en proceso'),
      ),
      _ when exam.canRegisterResult => (
        label: 'Registrar resultado',
        icon: Icons.edit_note,
        onPressed: () => _registerResult(exam),
      ),
      _ when exam.canValidateResult => (
        label: 'Validar resultado',
        icon: Icons.verified_outlined,
        onPressed: () => _run((s) => s.validateResult(exam.id), 'Resultado validado'),
      ),
      _ when exam.canComplete => (
        label: 'Completar examen',
        icon: Icons.task_alt,
        onPressed: () => _run((s) => s.complete(exam.id), 'Examen completado'),
      ),
      _ => null,
    };
    if (main == null && !exam.canCancel) return null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (exam.canCancel)
              Expanded(
                child: OutlinedButton(
                  key: const Key('exam.cancel'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: _busy ? null : () => _cancel(exam),
                  child: const Text('Cancelar'),
                ),
              ),
            if (exam.canCancel && main != null) const SizedBox(width: 12),
            if (main != null)
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const Key('exam.next'),
                  onPressed: _busy ? null : main.onPressed,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(main.icon),
                  label: Text(main.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.exam});

  final ClinicalExam exam;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.turquoiseSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ClinicalExamTile.iconFor(exam.type), color: AppColors.deepBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.type.label,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'Consulta #${exam.consultationId}',
                      style: text.labelMedium?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ExamStatusChip(status: exam.status),
            ],
          ),
          if (exam.indication != null) ...[
            const SizedBox(height: 12),
            Text('Indicación', style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(exam.indication!, style: text.bodyMedium),
          ],
          const Divider(height: 24),
          _Step(label: 'Solicitado', date: exam.requestedAt),
          if (exam.startedAt != null) _Step(label: 'Iniciado', date: exam.startedAt!),
          if (exam.completedAt != null) _Step(label: 'Completado', date: exam.completedAt!),
          if (exam.cancelledAt != null) ...[
            _Step(label: 'Cancelado', date: exam.cancelledAt!),
            if (exam.cancellationReason != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  'Motivo: ${exam.cancellationReason}',
                  style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: AppColors.turquoise),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            Formatters.date(date),
            style: text.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    );
  }
}
