import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/app.dart';

void main() {
  testWidgets('App boots into Home tab by default', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZenoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets); // app bar title
    expect(find.text('Welcome to Zeno'), findsOneWidget);
  });

  testWidgets(
    'Tapping Library tab navigates to library screen',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ZenoApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.library_books_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No decks yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Review tab navigates to review screen',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: ZenoApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.psychology_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to review'), findsOneWidget);
    },
  );
}
