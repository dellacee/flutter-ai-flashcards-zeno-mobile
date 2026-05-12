import 'package:flutter/material.dart';

/// Regex that matches at least one valid Anki-style cloze marker,
/// e.g. `{{c1::word}}`, `{{c2::phrase}}`.
final _clozeRegex = RegExp(r'\{\{c\d+::[^}]+\}\}');

/// Form for creating / editing a cloze-deletion flash card.
///
/// Validates that the text contains at least one {{cN::...}} marker.
/// Emits [onChange] on every keystroke.
class ClozeCardForm extends StatefulWidget {
  const ClozeCardForm({
    required this.onChange,
    super.key,
    this.initialText = '',
  });

  final String initialText;

  /// Emits (text, valid) as the user types.
  final void Function({
    required String text,
    required bool valid,
  }) onChange;

  @override
  State<ClozeCardForm> createState() => _ClozeCardFormState();
}

class _ClozeCardFormState extends State<ClozeCardForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_notify);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify() {
    final text = _controller.text;
    widget.onChange(
      text: text,
      valid: text.isNotEmpty && _clozeRegex.hasMatch(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Văn bản (đánh dấu chỗ trống bằng {{c1::từ cần che}})',
        alignLabelWithHint: true,
        helperText:
            'Ví dụ: Mitochondria là {{c1::nhà máy năng lượng}} của tế bào.',
        helperMaxLines: 2,
      ),
      maxLines: 5,
      textInputAction: TextInputAction.done,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Không được để trống.';
        if (!_clozeRegex.hasMatch(v)) {
          return 'Cần ít nhất một dấu cloze {{cN::...}}.';
        }
        return null;
      },
    );
  }
}
