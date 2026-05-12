import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/core/widgets/loading_skeleton.dart';

void main() {
  testWidgets('LoadingSkeleton uses default height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingSkeleton()),
      ),
    );

    final box = tester.getSize(find.byType(LoadingSkeleton));
    expect(box.height, 80);
  });

  testWidgets('LoadingSkeleton respects custom height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingSkeleton(height: 120)),
      ),
    );

    expect(tester.getSize(find.byType(LoadingSkeleton)).height, 120);
  });
}
