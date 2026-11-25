import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../domain/model/value_objects/patient_snapshot.dart';

/// Elige un paciente de la clínica en una hoja con buscador.
class PatientPicker extends StatelessWidget {
  const PatientPicker({
    super.key,
    required this.patients,
    required this.selected,
    required this.onSelected,
  });

  final List<PatientSnapshot> patients;
  final PatientSnapshot? selected;
  final ValueChanged<PatientSnapshot> onSelected;

  @override
  Widget build(BuildContext context) {
    return FormField<PatientSnapshot>(
      validator: (_) => selected == null ? 'Elige el paciente.' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.field,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: field.hasError && selected == null ? AppColors.danger : AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: const Key('consultation.patient'),
              leading: ProfileAvatar(
                imageUrl: selected?.photoUrl,
                fallbackIcon: Icons.pets,
                radius: 22,
              ),
              title: Text(selected?.name ?? 'Elige un paciente'),
              subtitle: selected == null ? null : Text(selected!.speciesAndBreed),
              trailing: const Icon(Icons.expand_more),
              onTap: () async {
                final patient = await showModalBottomSheet<PatientSnapshot>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  backgroundColor: AppColors.surface,
                  builder: (_) => _PatientSheet(patients: patients),
                );
                if (patient == null) return;
                onSelected(patient);
                field.didChange(patient);
              },
            ),
          ),
          if (field.hasError && selected == null) ...[
            const SizedBox(height: 6),
            Text(field.errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _PatientSheet extends StatefulWidget {
  const _PatientSheet({required this.patients});

  final List<PatientSnapshot> patients;

  @override
  State<_PatientSheet> createState() => _PatientSheetState();
}

class _PatientSheetState extends State<_PatientSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final found = widget.patients.where((p) => p.matches(_query)).toList();
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, raza o ID',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: found.isEmpty
                  ? Center(
                      child: Text(
                        widget.patients.isEmpty
                            ? 'Primero registra la mascota en Pacientes.'
                            : 'Ningún paciente coincide con la búsqueda.',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: found.length,
                      itemBuilder: (context, index) {
                        final patient = found[index];
                        return ListTile(
                          leading: ProfileAvatar(
                            imageUrl: patient.photoUrl,
                            fallbackIcon: Icons.pets,
                            radius: 22,
                          ),
                          title: Text(patient.name),
                          subtitle: Text('${patient.speciesAndBreed}\n${patient.code}'),
                          isThreeLine: true,
                          onTap: () => Navigator.of(context).pop(patient),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
