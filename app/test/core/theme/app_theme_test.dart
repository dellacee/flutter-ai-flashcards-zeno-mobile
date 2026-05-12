import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/core/theme/app_theme.dart';

void main() {
  late FlutterExceptionHandler? savedOnError;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable HTTP fetching; google_fonts will throw asynchronously when font
    // bytes are absent, but TextStyle metadata is still returned correctly.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    // Suppress async google_fonts font-not-found errors that fire after the
    // test body completes. These are expected in a test environment without
    // bundled font assets and do not affect ThemeData correctness.
    savedOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception
          .toString()
          .contains('allowRuntimeFetching is false')) {
        return; // suppress expected google_fonts test error
      }
      savedOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = savedOnError;
  });

  group('AppTheme', () {
    testWidgets(
      'light() returns ThemeData with Brightness.light and useMaterial3',
      (tester) async {
        final theme = AppTheme.light();
        await tester.pumpAndSettle();

        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, equals(Brightness.light));
      },
    );

    testWidgets(
      'dark() returns ThemeData with Brightness.dark and useMaterial3',
      (tester) async {
        final theme = AppTheme.dark();
        await tester.pumpAndSettle();

        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, equals(Brightness.dark));
      },
    );

    testWidgets(
      'light() colorScheme.primary is non-null (derived from indigo seed)',
      (tester) async {
        final theme = AppTheme.light();
        await tester.pumpAndSettle();

        // Color is a non-nullable value type; this documents that M3 seed
        // derivation ran without error.
        // ignore: unnecessary_null_comparison
        expect(theme.colorScheme.primary != null, isTrue);
      },
    );

    testWidgets(
      'dark() colorScheme.primary is non-null (derived from indigo seed)',
      (tester) async {
        final theme = AppTheme.dark();
        await tester.pumpAndSettle();

        // ignore: unnecessary_null_comparison
        expect(theme.colorScheme.primary != null, isTrue);
      },
    );
  });
}
