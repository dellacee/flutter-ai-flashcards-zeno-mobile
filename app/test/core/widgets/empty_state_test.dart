import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders icon, title, description', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'No decks',
            description: 'Create your first deck',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.text('No decks'), findsOneWidget);
    expect(find.text('Create your first deck'), findsOneWidget);
  });

  testWidgets('EmptyState renders optional action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'No decks',
            description: 'Create your first deck',
            action: FilledButton(
              onPressed: () {},
              child: const Text('New deck'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('New deck'), findsOneWidget);
  });
}
