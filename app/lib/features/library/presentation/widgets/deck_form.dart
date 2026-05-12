import 'package:flutter/material.dart';
import 'package:zeno/features/library/domain/deck.dart';

/// A reusable form for creating or editing a [Deck].
///
/// When [initialDeck] is provided the form pre-fills fields and the submit
/// button reads "Lưu" (edit mode). When it is null the form is in create mode
/// and the submit button reads "Tạo deck".
///
/// The [submitting] flag disables all fields and renders a progress indicator
/// inside the submit button.
class DeckForm extends StatefulWidget {
  /// Creates a [DeckForm].
  const DeckForm({
    required this.onSubmit,
    super.key,
    this.initialDeck,
    this.submitting = false,
  });

  /// When non-null, pre-fills the form fields with this deck's data.
  final Deck? initialDeck;

  /// Called when the user taps the submit button and the form is valid.
  final void Function({required String title, String? description}) onSubmit;

  /// When `true`, the fields and submit button are disabled and a loading
  /// indicator is shown inside the button.
  final bool submitting;

  @override
  State<DeckForm> createState() => _DeckFormState();
}

class _DeckFormState extends State<DeckForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialDeck?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDeck?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final rawDesc = _descriptionController.text.trim();
    final description = rawDesc.isEmpty ? null : rawDesc;
    widget.onSubmit(title: title, description: description);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialDeck != null;
    final disabled = widget.submitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            enabled: !disabled,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Tên deck',
              hintText: 'Ví dụ: Sinh học 12',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tên deck không được để trống.';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Description field (optional)
          TextFormField(
            controller: _descriptionController,
            enabled: !disabled,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mô tả (không bắt buộc)',
              hintText: 'Chủ đề, chương, ghi chú ngắn…',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          FilledButton(
            onPressed: disabled ? null : _submit,
            child: disabled
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEdit ? 'Lưu' : 'Tạo deck'),
          ),
        ],
      ),
    );
  }
}
