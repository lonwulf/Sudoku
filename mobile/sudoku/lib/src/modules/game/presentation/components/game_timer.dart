import 'dart:async';

import 'package:flutter/widgets.dart';

/// Elapsed play time as mm:ss. Give it a key per puzzle so a new puzzle
/// restarts the clock; [paused] stops it without resetting.
class GameTimer extends StatefulWidget {
  final TextStyle? style;
  final bool paused;

  const GameTimer({super.key, this.style, this.paused = false});

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  final Stopwatch stopwatch = Stopwatch();
  late final Timer ticker;

  @override
  void initState() {
    super.initState();
    if (!widget.paused) stopwatch.start();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (stopwatch.isRunning) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      stopwatch.stop();
    } else {
      stopwatch.start();
    }
  }

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = stopwatch.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$minutes:$seconds', style: widget.style);
  }
}
