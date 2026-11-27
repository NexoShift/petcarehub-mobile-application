import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/section_header.dart';
import '../../application/consultations_store.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import 'consultation_tile.dart';

/// "Atenciones clínicas" de una mascota (lista de consultas, la más reciente primero).
class PetConsultationsSection extends StatefulWidget {
  const PetConsultationsSection({
    super.key,
    required this.petId,
    this.limit,
    this.onOpen,
    this.onSeeAll,
    this.onRegister,
  });

  final int petId;

  /// Cuántas mostrar (null = todas).
  final int? limit;

  final ValueChanged<ClinicalConsultation>? onOpen;
  final VoidCallback? onSeeAll;

  /// Abrir una consulta nueva. Solo el veterinario.
  final VoidCallback? onRegister;

  @override
  State<PetConsultationsSection> createState() => _PetConsultationsSectionState();
}

class _PetConsultationsSectionState extends State<PetConsultationsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ConsultationsStore>().loadForPet(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationsStore>();
    final consultations = store.consultationsOf(widget.petId);
    final error = store.errorOf(widget.petId);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    Widget body;
    if (consultations == null && error == null) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (error != null) {
      body = Row(
        children: [
          Expanded(child: Text('No se pudieron cargar las consultas.', style: muted)),
          TextButton(
            onPressed: () => store.loadForPet(widget.petId, force: true),
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (consultations!.isEmpty) {
      body = Text('Aún no tiene consultas registradas.', style: muted);
    } else {
      final shown = widget.limit == null
          ? consultations
          : consultations.take(widget.limit!).toList();
      body = Column(
        children: [
          for (final c in shown) ...[
            ConsultationTile(
              consultation: c,
              onTap: widget.onOpen == null ? null : () => widget.onOpen!(c),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    final hasAny = consultations != null && consultations.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Atenciones clínicas${hasAny ? ' (${consultations.length})' : ''}',
          actionLabel: hasAny && widget.onSeeAll != null ? 'Ver historia' : null,
          onAction: widget.onSeeAll,
        ),
        const SizedBox(height: 8),
        body,
        if (widget.onRegister != null) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('pet.newConsultation'),
            onPressed: widget.onRegister,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Nueva consulta'),
          ),
        ],
      ],
    );
  }
}
