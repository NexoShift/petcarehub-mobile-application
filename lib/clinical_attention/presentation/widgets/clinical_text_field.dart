import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/widgets/labeled_field.dart';
import '../clinical_formatters.dart';

/// Campo de texto con etiqueta, contador de caracteres y validación de obligatorio.
class ClinicalTextField extends StatelessWidget {
  const ClinicalTextField({
    super.key,
    this.fieldKey,
    required this.label,
    required this.controller,
    required this.maxLength,
    this.hintText,
    this.requiredMessage,
    this.minLines = 1,
    this.maxLines = 4,
    this.autofocus = false,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLength;
  final String? hintText;

  /// Si se indica, el campo es obligatorio y este es su mensaje de error.
  final String? requiredMessage;
  final int minLines;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: requiredMessage == null ? label : '$label *',
      hint: requiredMessage == null ? 'Opcional' : null,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        autofocus: autofocus,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hintText),
        validator: (value) =>
            requiredMessage != null && (value ?? '').trim().isEmpty ? requiredMessage : null,
      ),
    );
  }
}

/// Campo numérico de una constante fisiológica, con su unidad.
class ClinicalNumberField extends StatelessWidget {
  const ClinicalNumberField({
    super.key,
    this.fieldKey,
    required this.label,
    required this.unit,
    required this.controller,
    required this.isValid,
    required this.invalidMessage,
    this.decimal = false,
    this.required = true,
  });

  final Key? fieldKey;
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool Function(double value) isValid;
  final String invalidMessage;
  final bool decimal;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: required ? '$label ($unit) *' : '$label ($unit)',
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
          LengthLimitingTextInputFormatter(7),
        ],
        decoration: const InputDecoration(errorMaxLines: 3),
        validator: (text) {
          if ((text ?? '').trim().isEmpty) return required ? invalidMessage : null;
          final value = ClinicalFormatters.parseDecimal(text);
          return value != null && isValid(value) ? null : invalidMessage;
        },
      ),
    );
  }
}
