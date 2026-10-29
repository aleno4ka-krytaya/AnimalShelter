import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration timeout;
  final Duration warningBefore;
  final Future<void> Function() onTimeout;

  const InactivityWatcher({
    super.key,
    required this.child,
    required this.enabled,
    required this.onTimeout,
    this.timeout = const Duration(minutes: 3),
    this.warningBefore = const Duration(seconds: 30),
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _timeoutTimer;

  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(_onKey);
    _restartTimers();
  }

  @override
  void didUpdateWidget(
    covariant InactivityWatcher oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled ||
        oldWidget.timeout != widget.timeout ||
        oldWidget.warningBefore != widget.warningBefore) {
      _restartTimers();
    }
  }

  bool _onKey(KeyEvent event) {
    _restartTimers();
    return false;
  }

  void _restartTimers() {
    _warningTimer?.cancel();
    _timeoutTimer?.cancel();

    if (!widget.enabled || !mounted) {
      return;
    }

    final warningDelay = widget.timeout - widget.warningBefore;

    _warningTimer = Timer(
      warningDelay.isNegative ? Duration.zero : warningDelay,
      _showWarning,
    );

    _timeoutTimer = Timer(
      widget.timeout,
      _expireSession,
    );
  }

  void _showWarning() {
    if (!mounted || !widget.enabled || _dialogOpen) {
      return;
    }

    _dialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Сессия скоро завершится',
          ),
          content: const Text(
            'Из-за отсутствия активности вы выйдете '
            'из системы через 30 секунд.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _dialogOpen = false;
                _restartTimers();
              },
              child: const Text(
                'Остаться в системе',
              ),
            ),
          ],
        );
      },
    ).then((_) {
      _dialogOpen = false;
    });
  }

  Future<void> _expireSession() async {
    if (!mounted) return;

    if (_dialogOpen) {
      _dialogOpen = false;

      Navigator.of(
        context,
        rootNavigator: true,
      ).maybePop();
    }

    await widget.onTimeout();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);

    _warningTimer?.cancel();
    _timeoutTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartTimers(),
      onPointerMove: (_) => _restartTimers(),
      onPointerSignal: (_) => _restartTimers(),
      child: widget.child,
    );
  }
}
