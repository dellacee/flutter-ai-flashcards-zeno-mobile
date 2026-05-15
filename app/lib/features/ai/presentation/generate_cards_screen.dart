import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/ai/domain/generated_card_draft.dart';
import 'package:zeno/features/ai/presentation/providers/ai_providers.dart';
import 'package:zeno/features/cards/domain/card_repository.dart';
import 'package:zeno/features/cards/presentation/providers/card_providers.dart';

/// Screen where the user pastes text, picks a count, and generates AI card
/// drafts to preview and bulk-save to a deck.
class GenerateCardsScreen extends ConsumerStatefulWidget {
  const GenerateCardsScreen({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<GenerateCardsScreen> createState() =>
      _GenerateCardsScreenState();
}

class _GenerateCardsScreenState extends ConsumerState<GenerateCardsScreen> {
  final _controller = TextEditingController();
  int _count = 10;
  bool _generating = false;
  bool _saving = false;
  List<GeneratedCardDraft> _drafts = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canGenerate =>
      _controller.text.length >= 50 && !_generating && !_saving;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _drafts = [];
    });
    try {
      final drafts = await ref.read(aiApiClientProvider).generateCards(
            text: _controller.text,
            count: _count,
          );
      if (!mounted) return;
      setState(() {
        _generating = false;
        _drafts = drafts;
      });
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            f.map(
              network: (n) => n.message ?? 'Lỗi kết nối',
              auth: (a) => a.message ?? 'Lỗi xác thực',
              notFound: (n) => n.message ?? 'Không tìm thấy',
              permission: (p) => p.message ?? 'Không có quyền',
              unknown: (u) => u.message ?? 'Lỗi không xác định',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _saveAll() async {
    if (_drafts.isEmpty || _saving) return;
    setState(() => _saving = true);

    final repo = ref.read(cardRepositoryProvider);
    var saved = 0;
    var failed = 0;

    for (final draft in _drafts) {
      final newDraft = _toNewCardDraft(draft);
      if (newDraft == null) {
        failed++;
        continue;
      }
      try {
        await repo.createCard(deckId: widget.deckId, draft: newDraft);
        saved++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final msg = failed == 0
        ? 'Đã lưu $saved card vào deck'
        : 'Lưu $saved card thành công, $failed thất bại';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (failed == 0) context.pop();
  }

  NewCardDraft? _toNewCardDraft(GeneratedCardDraft draft) {
    return switch (draft) {
      GeneratedQaDraft(:final front, :final back) =>
        QaDraft(front: front, back: back),
      GeneratedClozeDraft(:final text) => ClozeDraft(text: text),
      GeneratedMcqDraft(:final question, :final options, :final correctIndex) =>
        McqDraft(
          question: question,
          options: options,
          correctIndex: correctIndex,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo card bằng AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Source text input ---
            TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Dán nội dung bạn muốn học (PDF support sắp ra)...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
              ),
            ),

            const SizedBox(height: 16),

            // --- Count slider ---
            Row(
              children: [
                Text('Tạo $_count cards', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Slider(
                    value: _count.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    label: '$_count',
                    onChanged: _saving || _generating
                        ? null
                        : (v) => setState(() => _count = v.round()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --- Generate button ---
            FilledButton.icon(
              onPressed: _canGenerate ? _generate : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
            ),

            // --- Progress indicator ---
            if (_generating) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'AI đang đọc...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // --- Draft preview list ---
            if (_drafts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '${_drafts.length} card được tạo — xem trước:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...List.generate(_drafts.length, (i) {
                return _DraftPreviewTile(draft: _drafts[i], index: i + 1);
              }),
              const SizedBox(height: 16),

              // --- Save all button ---
              FilledButton.tonalIcon(
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu tất cả vào deck'),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft preview tile — inline widget, no Dismissible needed here
// ---------------------------------------------------------------------------

class _DraftPreviewTile extends StatelessWidget {
  const _DraftPreviewTile({required this.draft, required this.index});

  final GeneratedCardDraft draft;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (icon, title, subtitle) = switch (draft) {
      GeneratedQaDraft(:final front, :final back) => (
          Icons.help_outline,
          front,
          back,
        ),
      GeneratedClozeDraft(:final text) => (
          Icons.short_text,
          text,
          null,
        ),
      GeneratedMcqDraft(:final question, :final options) => (
          Icons.checklist,
          question,
          '${options.length} lựa chọn',
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          child: Text('$index', style: theme.textTheme.labelMedium),
        ),
        title: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}
