import 'package:firebase_core/firebase_core.dart';
import 'package:zeno/firebase_options.dart';

/// Initialize Firebase before the app starts.
///
/// Must be awaited from the entry-point after ensuring the Flutter binding
/// is initialized. App Check and Crashlytics activation are added later.
Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
