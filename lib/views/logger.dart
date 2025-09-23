import 'package:twokey/viewmodels/log_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:twokey/common/context.dart';

class LoggerPage extends StatelessWidget {
  const LoggerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          const _LoggerToolbar(),
          Expanded(
            child: Consumer<LogViewModel>(
              builder: (context, vm, _) {
                final entries = vm.entries;
                if (entries.isEmpty) {
                  return const Center(child: Text('No logs yet'));
                }
                return SelectionArea(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[entries.length - 1 - index];
                      final color = _colorForLevel(context, e.level);
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${_fmtTime(e.time)} [${e.level.name.toUpperCase()}] ${e.message}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: color,
                          ),
                        ),
                        subtitle: e.stackTrace != null
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  e.stackTrace.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  static Color _colorForLevel(BuildContext context, Level level) {
    switch (level) {
      case Level.error:
        return Colors.redAccent;
      case Level.warning:
        return Colors.orangeAccent;
      case Level.info:
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }
}

class _LoggerToolbar extends StatelessWidget {
  const _LoggerToolbar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LogViewModel>();
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: vm.paused ? 'Resume' : 'Pause',
                icon: Icon(vm.paused ? Icons.play_arrow : Icons.pause),
                onPressed: vm.togglePause,
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_outline),
                onPressed: vm.clear,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: vm.minLevel == null,
                        onSelected: (_) => vm.setMinLevel(null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Debug+'),
                        selected: vm.minLevel == Level.debug,
                        onSelected: (_) => vm.setMinLevel(Level.debug),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Info+'),
                        selected: vm.minLevel == Level.info,
                        onSelected: (_) => vm.setMinLevel(Level.info),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Warn+'),
                        selected: vm.minLevel == Level.warning,
                        onSelected: (_) => vm.setMinLevel(Level.warning),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Error'),
                        selected: vm.minLevel == Level.error,
                        onSelected: (_) => vm.setMinLevel(Level.error),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
