import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/app.dart';

void main() {
  testWidgets('ZenoApp renders bootstrap placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZenoApp()),
    );

    expect(find.text('Zeno'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);
  });
}
