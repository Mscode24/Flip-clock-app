import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class ChessDisplay extends StatelessWidget {
  final CustomTheme theme;
  final double scaleFactor;
  final int p1Ms, p2Ms, p1Moves, p2Moves, activePlayer;
  final bool gameFinished, isLandscape;
  final VoidCallback onTapP1, onTapP2, onPause, onReset;

  const ChessDisplay({
    super.key,
    required this.theme,
    required this.scaleFactor,
    required this.p1Ms,
    required this.p2Ms,
    required this.activePlayer,
    required this.gameFinished,
    required this.onTapP1,
    required this.onTapP2,
    required this.onPause,
    required this.onReset,
    required this.p1Moves,
    required this.p2Moves,
    required this.isLandscape,
  });

  String _fmt(int ms) {
    int totalSec = (ms / 1000).ceil();
    int h = totalSec ~/ 3600;
    int m = (totalSec % 3600) ~/ 60;
    int s = totalSec % 60;

    if (h > 0) return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    // Show tenths if under 20 seconds
    if (totalSec < 20 && ms > 0) {
       int tenths = (ms ~/ 100) % 10;
       return "$m:${s.toString().padLeft(2,'0')}.$tenths";
    }
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF121212)), // Background
        Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          children: [
            Expanded(
              child: _buildElegantPlayerBlock(
                timeText: _fmt(p2Ms),
                moves: p2Moves,
                isActive: activePlayer == 2,
                onTap: onTapP2,
                quarterTurns: isLandscape ? 1 : 2, 
              ),
            ),
            SizedBox(
              width: isLandscape ? 80 * scaleFactor : double.infinity,
              height: isLandscape ? double.infinity : 80 * scaleFactor,
            ),
            Expanded(
              child: _buildElegantPlayerBlock(
                timeText: _fmt(p1Ms),
                moves: p1Moves,
                isActive: activePlayer == 1,
                onTap: onTapP1,
                quarterTurns: isLandscape ? 3 : 0, 
              ),
            ),
          ],
        ),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10 : 30, vertical: isLandscape ? 30 : 10),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10, width: 1),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Flex(
              direction: isLandscape ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: activePlayer == 0 ? null : onPause,
                  icon: Icon(activePlayer == 0 ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  iconSize: 32 * scaleFactor,
                  color: activePlayer == 0 ? Colors.greenAccent : Colors.amberAccent,
                ),
                SizedBox(width: isLandscape ? 0 : 20, height: isLandscape ? 20 : 0),
                IconButton(onPressed: onReset, icon: const Icon(Icons.refresh_rounded), iconSize: 28 * scaleFactor, color: Colors.white54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantPlayerBlock({
    required String timeText,
    required int moves,
    required bool isActive,
    required VoidCallback onTap,
    required int quarterTurns,
  }) {
    final Color baseColor = isActive 
        ? theme.cardColor.withOpacity(theme.cardOpacity) 
        : const Color(0xFF1A1A1A).withOpacity(theme.cardOpacity);
        
    final Color textColor = isActive ? theme.digitColor : Colors.grey[700]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          gradient: isActive 
              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [baseColor.withOpacity(0.8 * theme.cardOpacity), baseColor])
              : null,
          boxShadow: isActive ? [BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 1)] : [],
          border: isActive ? Border.all(color: Colors.white24, width: 1) : Border.all(color: Colors.transparent, width: 0),
        ),
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Stack(
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 140 * scaleFactor, fontWeight: FontWeight.w700, color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: isActive ? [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))] : [],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 6 * scaleFactor),
                    decoration: BoxDecoration(color: isActive ? Colors.black26 : Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: Text("MOVES: $moves", style: TextStyle(fontSize: 14 * scaleFactor, color: isActive ? textColor.withOpacity(0.9) : Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ),
              if (!isActive && !gameFinished)
                 Positioned(top: 20, right: 20, child: Icon(Icons.touch_app, color: Colors.white10, size: 40 * scaleFactor)),
            ],
          ),
        ),
      ),
    );
  }
}