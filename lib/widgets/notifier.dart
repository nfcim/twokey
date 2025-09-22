import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class NotifierMessage {
  final String id;
  final String text;
  final Duration? duration; // null means persistent
  final Color? backgroundColor;

  const NotifierMessage({
    required this.id,
    required this.text,
    this.duration,
    this.backgroundColor,
  });
}

class NotifierHost extends StatefulWidget {
  final Widget child;
  const NotifierHost({super.key, required this.child});

  static NotifierHostState? of(BuildContext context) {
    return context.findAncestorStateOfType<NotifierHostState>();
  }

  @override
  State<NotifierHost> createState() => NotifierHostState();
}

class NotifierHostState extends State<NotifierHost> {
  final List<NotifierMessage> _toastQueue = <NotifierMessage>[];
  NotifierMessage? _currentToast;
  bool _showing = false;

  Future<void> showToast(
    String text, {
    Duration? duration, // null => default 1500
    Color? backgroundColor,
  }) async {
    _toastQueue.add(
      NotifierMessage(
        id: UniqueKey().toString(),
        text: text,
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
    if (!_showing) {
      // ignore: unawaited_futures
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_showing) return;
    _showing = true;
    try {
      while (_toastQueue.isNotEmpty) {
        final next = _toastQueue.removeAt(0);
        _currentToast = next;
        if (mounted) setState(() {});
        final d = next.duration ?? const Duration(milliseconds: 1500);
        await Future.delayed(d);
        if (_currentToast?.id == next.id) {
          _currentToast = null;
          if (mounted) setState(() {});
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotifierMessage? visible = _currentToast;
    return Stack(
      children: [
        widget.child,
        if (visible != null)
          _NotifierCard(key: ValueKey(visible.id), message: visible),
      ],
    );
  }
}

class _NotifierCard extends StatelessWidget {
  final NotifierMessage message;
  const _NotifierCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 8,
            left: 12,
            right: 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Color background =
                  message.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHigh;
              return Material(
                elevation: 10,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                color: background,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: min(constraints.maxWidth, 500),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Text(message.text),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Notifier {
  Notifier._();
  static final Notifier instance = Notifier._();
  static final GlobalKey<NotifierHostState> hostKey =
      GlobalKey<NotifierHostState>();

  Future<void> show(
    String text, {
    Duration? duration, // null => default 1500
    Color? backgroundColor,
  }) async {
    final state = hostKey.currentState;
    if (state == null) return;
    await state.showToast(
      text,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }
}
