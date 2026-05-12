import 'package:flutter/material.dart';

/// Form for creating / editing a multiple-choice flash card.
///
/// Starts with 2 empty options (minimum). User can add up to 6.
/// A [RadioGroup] ancestor manages which option is the correct answer.
/// Each option row has an [IconButton] to remove it (disabled when only 2
/// options remain).
///
/// Emits [onChange] on every change so the parent can gate the Save button.
class McqCardForm extends StatefulWidget {
  const McqCardForm({
    required this.onChange,
    super.key,
    this.initialQuestion = '',
    this.initialOptions = const ['', ''],
    this.initialCorrectIndex = 0,
  });

  final String initialQuestion;
  final List<String> initialOptions;
  final int initialCorrectIndex;

  /// Emits (question, options, correctIndex, valid) on every change.
  final void Function({
    required String question,
    required List<String> options,
    required int correctIndex,
    required bool valid,
  }) onChange;

  @override
  State<McqCardForm> createState() => _McqCardFormState();
}

class _McqCardFormState extends State<McqCardForm> {
  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion);
    _questionController.addListener(_notify);

    // Ensure at least 2 option slots.
    final initial =
        widget.initialOptions.length >= 2 ? widget.initialOptions : ['', ''];
    _optionControllers = initial
        .map((o) => TextEditingController(text: o)..addListener(_notify))
        .toList();

    _correctIndex = widget.initialCorrectIndex.clamp(
      0,
      _optionControllers.length - 1,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() {
    final question = _questionController.text.trim();
    final options = _optionControllers.map((c) => c.text).toList();
    final nonEmptyCount = options.where((o) => o.trim().isNotEmpty).length;
    final correctNonEmpty =
        _correctIndex < options.length &&
        options[_correctIndex].trim().isNotEmpty;

    widget.onChange(
      question: question,
      options: options,
      correctIndex: _correctIndex,
      valid: question.isNotEmpty && nonEmptyCount >= 2 && correctNonEmpty,
    );
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() {
      _optionControllers.add(TextEditingController()..addListener(_notify));
    });
    _notify();
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (_correctIndex >= _optionControllers.length) {
        _correctIndex = _optionControllers.length - 1;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question field
        TextFormField(
          controller: _questionController,
          decoration: const InputDecoration(labelText: 'Câu hỏi'),
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Không được để trống.' : null,
        ),

        const SizedBox(height: 16),

        // RadioGroup manages the selected option index.
        RadioGroup<int>(
          groupValue: _correctIndex,
          onChanged: (v) {
            if (v != null) {
              setState(() => _correctIndex = v);
              _notify();
            }
          },
          child: Column(
            children: [
              for (int i = 0; i < _optionControllers.length; i++) ...[
                _OptionRow(
                  index: i,
                  controller: _optionControllers[i],
                  canRemove: _optionControllers.length > 2,
                  onRemove: () => _removeOption(i),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // Add option button
        if (_optionControllers.length < 6)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Thêm lựa chọn'),
            ),
          ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Radio uses the RadioGroup ancestor's groupValue automatically.
        Radio<int>(value: index),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Lựa chọn ${index + 1}',
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Xóa lựa chọn',
          onPressed: canRemove ? onRemove : null,
        ),
      ],
    );
  }
}
