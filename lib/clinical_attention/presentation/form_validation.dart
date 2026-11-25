import 'package:material_ui/material_ui.dart';

/// Valida el formulario y, si algo falta, lleva la pantalla al primer error.
///
/// Los formularios clínicos son largos: sin esto, el error puede quedar fuera
/// de la pantalla y el botón parece no hacer nada.
bool validateAndReveal(GlobalKey<FormState> formKey) {
  final invalid = formKey.currentState!.validateGranularly();
  if (invalid.isEmpty) return true;

  double top(FormFieldState<Object?> field) {
    final box = field.context.findRenderObject();
    return box is RenderBox ? box.localToGlobal(Offset.zero).dy : double.infinity;
  }

  final first = invalid.reduce((a, b) => top(a) <= top(b) ? a : b);
  Scrollable.ensureVisible(
    first.context,
    alignment: 0.2,
    duration: const Duration(milliseconds: 300),
  );
  return false;
}
