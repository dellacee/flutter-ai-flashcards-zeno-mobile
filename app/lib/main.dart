import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/app.dart';
import 'package:zeno/core/firebase/firebase_init.dart';
import 'package:zeno/core/logger/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger();
  try {
    await initFirebase();
    runApp(const ProviderScope(child: ZenoApp()));
  } catch (error, stackTrace) {
    debugPrint('FATAL: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_BootstrapError(error: error, stackTrace: stackTrace));
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bootstrap failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('$error', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(
                    stackTrace.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
