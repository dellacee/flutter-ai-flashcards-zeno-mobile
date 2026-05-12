import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/app.dart';

void main() {
  testWidgets('ZenoApp boots without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZenoApp()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
