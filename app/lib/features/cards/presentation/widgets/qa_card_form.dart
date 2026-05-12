import 'package:flutter/material.dart';

/// Form for creating / editing a Q&A flash card.
///
/// Emits [onChange] on every keystroke so the parent screen can enable
/// or disable the Save button reactively without needing a form key.
class QaCardForm extends StatefulWidget {
  const QaCardForm({
    required this.onChange,
    super.key,
    this.initialFront = '',
    this.initialBack = '',
  });

  final String initialFront;
  final String initialBack;

  /// Emits (front, back, valid) as the user types.
  final void Function({
    required String front,
    required String back,
    required bool valid,
  }) onChange;

  @override
  State<QaCardForm> createState() => _QaCardFormState();
}

class _QaCardFormState extends State<QaCardForm> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.initialFront);
    _backController = TextEditingController(text: widget.initialBack);

    _frontController.addListener(_notify);
    _backController.addListener(_notify);

    // Emit initial state so parent reflects pre-filled validity.
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _notify() {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    widget.onChange(
      front: front,
      back: back,
      valid: front.isNotEmpty && back.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _frontController,
          decoration: const InputDecoration(
            labelText: 'Mặt trước (câu hỏi)',
          ),
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Không được để trống.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _backController,
          decoration: const InputDecoration(
            labelText: 'Mặt sau (đáp án)',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textInputAction: TextInputAction.done,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Không được để trống.' : null,
        ),
      ],
    );
  }
}
