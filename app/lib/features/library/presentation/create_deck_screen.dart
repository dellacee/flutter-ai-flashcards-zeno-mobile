import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/core/error/app_failure.dart';
import 'package:zeno/features/library/presentation/providers/deck_providers.dart';
import 'package:zeno/features/library/presentation/widgets/deck_form.dart';

/// Screen for creating a new deck.
///
/// Renders [DeckForm] with no initial deck (create mode). On successful
/// submission navigates to the new deck's detail page via [GoRouter.go] so
/// the back button does not return to this screen.
class CreateDeckScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateDeckScreen].
  const CreateDeckScreen({super.key});

  @override
  ConsumerState<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends ConsumerState<CreateDeckScreen> {
  bool _submitting = false;

  Future<void> _handleSubmit({
    required String title,
    String? description,
  }) async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(deckRepositoryProvider);
      final newDeck = await repo.createDeck(
        title: title,
        description: description,
      );
      if (!mounted) return;
      context.go('/decks/${newDeck.id}');
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
    return Scaffold(
      appBar: AppBar(title: const Text('New deck')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: DeckForm(
          onSubmit: _handleSubmit,
          submitting: _submitting,
        ),
      ),
    );
  }
}
