import 'dart:async';
import 'package:twokey/common/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LogViewModel extends ChangeNotifier {
  final int maxEntries;
  final List<LogEntry> _buffer = <LogEntry>[];
  bool paused = false;
  Level? minLevel;
  StreamSubscription<LogEntry>? _sub;

  LogViewModel(Stream<LogEntry> stream, {this.maxEntries = 1000}) {
    _sub = stream.listen(_onLog);
  }

  void _onLog(LogEntry entry) {
    if (paused) return;
    _buffer.add(entry);
    final overflow = _buffer.length - maxEntries;
    if (overflow > 0) _buffer.removeRange(0, overflow);
    notifyListeners();
  }

  List<LogEntry> get entries => minLevel == null
      ? _buffer
      : _buffer.where((e) => e.level.index >= minLevel!.index).toList();

  void clear() {
    _buffer.clear();
    notifyListeners();
  }

  void togglePause() {
    paused = !paused;
    notifyListeners();
  }

  void setMinLevel(Level? level) {
    minLevel = level;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
