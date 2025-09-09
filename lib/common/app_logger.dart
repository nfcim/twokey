import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logger wrapper to control formatting & redaction.
class AppLogger {
  AppLogger._();
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      printEmojis: false,
      noBoxingByDefault: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    level: kReleaseMode ? Level.info : Level.debug,
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warn(String message) => _logger.w(message);
  static void error(String message, [Object? error, StackTrace? st]) =>
      _logger.e(message, error: error, stackTrace: st);

  /// For sensitive payloads: only log in debug; redact in release.
  static void sensitive(String label, String redactedHint) {
    if (kReleaseMode) {
      _logger.i('$label: <redacted>');
    } else {
      _logger.d('$label: $redactedHint');
    }
  }
}
