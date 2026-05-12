import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/features/cards/presentation/widgets/cloze_card_form.dart';

void main() {
  testWidgets('invalid without cloze marker', (tester) async {
    bool? lastValid;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClozeCardForm(
            onChange: ({required text, required valid}) => lastValid = valid,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField),
      'plain text without marker',
    );
    await tester.pump();
    expect(lastValid, isFalse);
  });

  testWidgets('valid with cloze marker', (tester) async {
    bool? lastValid;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClozeCardForm(
            onChange: ({required text, required valid}) => lastValid = valid,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField),
      'Mitochondria is the {{c1::powerhouse}}',
    );
    await tester.pump();
    expect(lastValid, isTrue);
  });
}
