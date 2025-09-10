import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logger wrapper to control formatting & redaction.
class AppLogger {
  AppLogger._();

  /// Structured log entry used by the in-app Logger UI.
  static final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  /// Stream of structured logs emitted by AppLogger methods.
  static Stream<LogEntry> get stream => _controller.stream;

  static void _emit(
    Level level,
    String message, [
    Object? error,
    StackTrace? st,
  ]) {
    try {
      _controller.add(
        LogEntry(
          time: DateTime.now(),
          level: level,
          message: message,
          error: error,
          stackTrace: st,
        ),
      );
    } catch (_) {
      // Swallow stream errors to avoid affecting app logging.
    }
  }

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

  static void debug(String message) {
    _emit(Level.debug, message);
    _logger.d(message);
  }

  static void info(String message) {
    _emit(Level.info, message);
    _logger.i(message);
  }

  static void warn(String message) {
    _emit(Level.warning, message);
    _logger.w(message);
  }

  static void error(String message, [Object? error, StackTrace? st]) {
    _emit(Level.error, message, error, st);
    _logger.e(message, error: error, stackTrace: st);
  }

  /// For sensitive payloads: only log in debug; redact in release.
  static void sensitive(String label, String redactedHint) {
    if (kReleaseMode) {
      _logger.i('$label: <redacted>');
    } else {
      _logger.d('$label: $redactedHint');
    }
  }
}

/// Data class for a single log entry.
class LogEntry {
  final DateTime time;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });
}
