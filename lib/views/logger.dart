import 'package:fauth/viewmodels/log_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class LoggerPage extends StatelessWidget {
  const LoggerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                return ListView.builder(
                  reverse: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[entries.length - 1 - index];
                    final color = _colorForLevel(context, e.level);
                    return ListTile(
                      dense: true,
                      title: SelectableText(
                        '${_fmtTime(e.time)} [${e.level.name.toUpperCase()}] ${e.message}',
                        style: TextStyle(fontFamily: 'monospace', color: color),
                      ),
                      subtitle: e.stackTrace != null
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SelectableText(
                                e.stackTrace.toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            )
                          : null,
                    );
                  },
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: vm.paused ? 'Resume' : 'Pause',
                icon: Icon(vm.paused ? Icons.play_arrow : Icons.pause),
                onPressed: vm.togglePause,
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear_all),
                onPressed: vm.clear,
              ),
              const SizedBox(width: 8),
              DropdownButton<Level?>(
                value: vm.minLevel,
                hint: const Text('Level: All'),
                items: const [
                  DropdownMenuItem<Level?>(value: null, child: Text('All')),
                  DropdownMenuItem<Level?>(
                    value: Level.debug,
                    child: Text('Debug+'),
                  ),
                  DropdownMenuItem<Level?>(
                    value: Level.info,
                    child: Text('Info+'),
                  ),
                  DropdownMenuItem<Level?>(
                    value: Level.warning,
                    child: Text('Warn+'),
                  ),
                  DropdownMenuItem<Level?>(
                    value: Level.error,
                    child: Text('Error'),
                  ),
                ],
                onChanged: (v) => vm.setMinLevel(v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
