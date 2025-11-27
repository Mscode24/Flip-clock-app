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

    if (h > 0) {
      return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Determine rotation based on orientation
    // Landscape: Players sit left/right. Portrait: Top/Bottom.
    
    return Stack(
      children: [
        // BACKGROUND CONTAINER (Gap filler)
        Container(color: const Color(0xFF121212)),

        // MAIN LAYOUT
        Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          children: [
            // --- PLAYER 2 (Opponent) ---
            Expanded(
              child: _buildElegantPlayerBlock(
                timeText: _fmt(p2Ms),
                moves: p2Moves,
                isActive: activePlayer == 2,
                onTap: onTapP2,
                // In Portrait: Rotate 180 (Upside down). In Landscape: Rotate 90 (Face Center)
                quarterTurns: isLandscape ? 1 : 2, 
                isOpponent: true,
              ),
            ),

            // --- CENTER CONTROL GAP ---
            // This is just a spacer, the actual buttons float on top
            SizedBox(
              width: isLandscape ? 80 * scaleFactor : double.infinity,
              height: isLandscape ? double.infinity : 80 * scaleFactor,
            ),

            // --- PLAYER 1 (You) ---
            Expanded(
              child: _buildElegantPlayerBlock(
                timeText: _fmt(p1Ms),
                moves: p1Moves,
                isActive: activePlayer == 1,
                onTap: onTapP1,
                // In Portrait: Normal. In Landscape: Rotate 270 (Face Center)
                quarterTurns: isLandscape ? 3 : 0, 
                isOpponent: false,
              ),
            ),
          ],
        ),

        // --- FLOATING CONTROL CAPSULE ---
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 10 : 30, 
              vertical: isLandscape ? 30 : 10
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10, width: 1),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
              ],
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
                SizedBox(
                  width: isLandscape ? 0 : 20,
                  height: isLandscape ? 20 : 0,
                ),
                IconButton(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 28 * scaleFactor,
                  color: Colors.white54,
                ),
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
    required bool isOpponent,
  }) {
    // 1. Color Palette
    // Active: Uses the user's Theme Card Color (with a gradient)
    // Inactive: Deep Dark Grey (almost black)
    
    final Color baseColor = isActive 
        ? theme.cardColor 
        : const Color(0xFF1A1A1A);
        
    final Color textColor = isActive 
        ? theme.digitColor 
        : Colors.grey[700]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4), // Tiny gap between blocks
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16), // Rounded corners looks cleaner
          gradient: isActive 
              ? LinearGradient(
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor.withOpacity(0.8),
                    baseColor,
                  ],
                )
              : null,
          boxShadow: isActive 
              ? [BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 1)]
              : [],
          border: isActive 
              ? Border.all(color: Colors.white24, width: 1)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Stack(
            children: [
              // Main Time Display
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 140 * scaleFactor,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: isActive 
                          ? [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))]
                          : [],
                      ),
                    ),
                  ),
                ),
              ),

              // Move Counter Pill
              Positioned(
                bottom: 20,
                left: 0, 
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 6 * scaleFactor),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black26 : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "MOVES: $moves",
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color: isActive ? textColor.withOpacity(0.9) : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              
              // "Tap Indicator" (Optional, subtle icon)
              if (!isActive && !gameFinished)
                 Positioned(
                   top: 20,
                   right: 20,
                   child: Icon(Icons.touch_app, color: Colors.white10, size: 40 * scaleFactor),
                 )
            ],
          ),
        ),
      ),
    );
  }
}