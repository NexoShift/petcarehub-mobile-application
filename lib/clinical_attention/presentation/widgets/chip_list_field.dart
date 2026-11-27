import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';

/// Lista de textos cortos: sugerencias que se tocan y un campo para agregar otros.
class ChipListField extends StatefulWidget {
  const ChipListField({
    super.key,
    required this.values,
    required this.onChanged,
    required this.hintText,
    required this.maxItems,
    required this.maxItemLength,
    this.suggestions = const [],
    this.inputKey,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final int maxItems;
  final int maxItemLength;
  final List<String> suggestions;
  final Key? inputKey;

  @override
  State<ChipListField> createState() => ChipListFieldState();
}

class ChipListFieldState extends State<ChipListField> {
  final _input = TextEditingController();

  bool get _full => widget.values.length >= widget.maxItems;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool _contains(String value) =>
      widget.values.any((item) => item.toLowerCase() == value.toLowerCase());

  void _toggle(String value) {
    if (_contains(value)) {
      widget.onChanged(
        widget.values.where((item) => item.toLowerCase() != value.toLowerCase()).toList(),
      );
    } else if (!_full) {
      widget.onChanged([...widget.values, value]);
    }
  }

  /// Agrega lo que quedó escrito sin confirmar, para no perderlo al registrar.
  List<String> commitPending() {
    final value = _input.text.trim();
    _input.clear();
    if (value.isEmpty || _contains(value) || _full) return widget.values;
    final values = [...widget.values, value];
    widget.onChanged(values);
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.values.where(
      (value) => !widget.suggestions.any((s) => s.toLowerCase() == value.toLowerCase()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final suggestion in widget.suggestions)
              FilterChip(
                label: Text(suggestion),
                selected: _contains(suggestion),
                onSelected: (_) => _toggle(suggestion),
                selectedColor: AppColors.navy,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.field,
                side: const BorderSide(color: AppColors.border),
                labelStyle: TextStyle(
                  color: _contains(suggestion) ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            for (final value in custom)
              InputChip(
                label: Text(value),
                onDeleted: () => _toggle(value),
                deleteButtonTooltipMessage: 'Quitar',
                backgroundColor: AppColors.turquoiseSoft,
                side: BorderSide.none,
                labelStyle: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        if (widget.suggestions.isNotEmpty || custom.isNotEmpty) const SizedBox(height: 8),
        TextField(
          key: widget.inputKey,
          controller: _input,
          enabled: !_full,
          maxLength: widget.maxItemLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => commitPending(),
          decoration: InputDecoration(
            counterText: '',
            hintText: _full ? 'Máximo ${widget.maxItems}' : widget.hintText,
            suffixIcon: IconButton(
              tooltip: 'Agregar',
              icon: const Icon(Icons.add_circle_outline, color: AppColors.turquoise),
              onPressed: _full ? null : commitPending,
            ),
          ),
        ),
      ],
    );
  }
}
