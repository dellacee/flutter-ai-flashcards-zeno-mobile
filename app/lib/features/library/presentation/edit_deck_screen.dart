import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/core/widgets/empty_state.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';
import 'package:zeno/features/library/presentation/widgets/deck_form.dart';

/// Screen for editing an existing deck.
///
/// Reads [deckByIdProvider] to pre-fill [DeckForm]. On submit calls
/// the repository's `updateDeck` method and pops back to the detail screen.
class EditDeckScreen extends ConsumerStatefulWidget {
  /// Creates an [EditDeckScreen].
  const EditDeckScreen({required this.deckId, super.key});

  /// The Firestore document id for the deck to edit.
  final String deckId;

  @override
  ConsumerState<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends ConsumerState<EditDeckScreen> {
  bool _submitting = false;

  Future<void> _handleSubmit({
    required String title,
    String? description,
  }) async {
    final deckAsync = ref.read(deckByIdProvider(widget.deckId));
    final deck = deckAsync.valueOrNull;
    if (deck == null) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(deckRepositoryProvider);
      await repo.updateDeck(
        deck.copyWith(title: title, description: description),
      );
      if (!mounted) return;
      context.pop();
    } on AppFailure catch (f) {
      if (!mounted) return;
      final message = f.whenOrNull(
            auth: (code, msg) => msg ?? 'Lỗi xác thực ($code).',
            network: (msg) =>
                msg ?? 'Lỗi mạng. Kiểm tra kết nối rồi thử lại.',
            notFound: (msg) => msg ?? 'Không tìm thấy.',
            permission: (msg) => msg ?? 'Không có quyền.',
            unknown: (msg, _) => msg ?? 'Có lỗi không xác định.',
          ) ??
          f.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckByIdProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sửa deck')),
      body: deckAsync.when(
        data: (deck) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: DeckForm(
            initialDeck: deck,
            onSubmit: _handleSubmit,
            submitting: _submitting,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Không tìm thấy deck',
          description: e.toString(),
        ),
      ),
    );
  }
}
