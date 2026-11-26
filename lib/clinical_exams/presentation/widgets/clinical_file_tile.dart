import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../application/clinical_exams_store.dart';
import '../../domain/model/clinical_file.dart';
import '../../domain/model/clinical_file_type.dart';

/// Image files show a thumbnail that opens full screen; videos and PDFs are listed only.
class ClinicalFileTile extends StatefulWidget {
  const ClinicalFileTile({super.key, required this.examId, required this.file});

  final int examId;
  final ClinicalFile file;

  static String sizeOf(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';

  @override
  State<ClinicalFileTile> createState() => _ClinicalFileTileState();
}

class _ClinicalFileTileState extends State<ClinicalFileTile> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.file.isImage) {
      _bytes = context.read<ClinicalExamsStore>().fileBytes(widget.examId, widget.file.id);
    }
  }

  void _open(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes))),
            ),
            SafeArea(
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final text = Theme.of(context).textTheme;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          '${ClinicalFileTile.sizeOf(file.sizeBytes)} · ${Formatters.date(file.uploadedAt)}',
          style: text.labelSmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );

    if (_bytes == null) {
      return AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              file.type == ClinicalFileType.video
                  ? Icons.videocam_outlined
                  : Icons.picture_as_pdf_outlined,
              color: AppColors.danger,
            ),
            const SizedBox(width: 12),
            Expanded(child: details),
          ],
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: bytes == null ? null : () => _open(bytes),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: switch (snapshot) {
                    AsyncSnapshot(hasError: true) => const ColoredBox(
                      color: AppColors.background,
                      child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                    ),
                    _ when bytes == null => const ColoredBox(
                      color: AppColors.background,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    _ => Image.memory(bytes, fit: BoxFit.cover),
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: details),
                  if (bytes != null) const Icon(Icons.zoom_in, color: AppColors.turquoise),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
