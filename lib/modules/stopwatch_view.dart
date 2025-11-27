import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../widgets/digit_card.dart';

class StopwatchDisplay extends StatefulWidget {
  final CustomTheme theme;
  final double scaleFactor;
  const StopwatchDisplay({super.key, required this.theme, required this.scaleFactor});
  @override
  State<StopwatchDisplay> createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends State<StopwatchDisplay> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _formatted = "00:00:00";
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_stopwatch.isRunning) setState(() => _formatted = _formatTime(_stopwatch.elapsedMilliseconds));
    });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  String _formatTime(int ms) {
    int hundreds = (ms / 10).truncate() % 100;
    int seconds = (ms / 1000).truncate() % 60;
    int minutes = (ms / (1000 * 60)).truncate() % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${hundreds.toString().padLeft(2, '0')}";
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double shortSide = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
        List<String> parts = _formatted.split(':');
        double finalSize = (shortSide * 0.35) * widget.scaleFactor;
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DigitCard(mainText: parts[0], size: finalSize, theme: widget.theme),
                    Text(":", style: TextStyle(fontSize: finalSize * 0.5, color: Colors.white54)),
                    DigitCard(mainText: parts[1], size: finalSize, theme: widget.theme),
                    Text(".", style: TextStyle(fontSize: finalSize * 0.5, color: Colors.white54)),
                    DigitCard(mainText: parts[2], size: finalSize * 0.7, theme: widget.theme),
                  ],
                ),
                SizedBox(height: finalSize * 0.2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(backgroundColor: widget.theme.cardColor, heroTag: "play", onPressed: () => setState(() => _stopwatch.isRunning ? _stopwatch.stop() : _stopwatch.start()), child: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow, color: widget.theme.digitColor, size: 30)),
                    const SizedBox(width: 30),
                    FloatingActionButton(backgroundColor: Colors.white24, heroTag: "reset", onPressed: () => setState(() { _stopwatch.reset(); _formatted = "00:00:00"; }), child: const Icon(Icons.refresh, color: Colors.white)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}