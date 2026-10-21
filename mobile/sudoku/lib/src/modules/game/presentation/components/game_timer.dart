import 'dart:async';

import 'package:flutter/widgets.dart';

/// Elapsed play time as mm:ss. Give it a key per puzzle so a new puzzle
/// restarts the clock.
class GameTimer extends StatefulWidget {
  final TextStyle? style;

  const GameTimer({super.key, this.style});

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  final Stopwatch stopwatch = Stopwatch()..start();
  late final Timer ticker;

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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
