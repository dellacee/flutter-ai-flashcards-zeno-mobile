import 'dart:developer' as developer;

import 'package:logging/logging.dart';

void initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    developer.log(
      rec.message,
      name: rec.loggerName,
      time: rec.time,
      level: rec.level.value,
      error: rec.error,
      stackTrace: rec.stackTrace,
    );
  });
}

Logger appLog(String name) => Logger(name);
