import 'package:flutter/material.dart';
import '../models/app_models.dart';

class DigitCard extends StatelessWidget {
  final String mainText;
  final double size;
  final CustomTheme theme;
  final String? topLabel;
  final String? bottomLeftLabel;
  final String? bottomRightLabel;
  final double auxScale; // Your aux scale logic

  const DigitCard({
    super.key, 
    required this.mainText, 
    required this.size, 
    required this.theme,
    this.topLabel,
    this.bottomLeftLabel,
    this.bottomRightLabel,
    this.auxScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double topFontSize = size * 0.08 * auxScale;
    double cornerFontSize = size * 0.12 * auxScale;
    double mainFontSize = size * 0.75;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(size*0.02, size*0.02), blurRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top Label (Date/Day)
          if (topLabel != null)
            Positioned(
              top: size * 0.06,
              child: Text(
                topLabel!,
                style: TextStyle(fontSize: topFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),

          // Main Number
          Text(
            mainText, 
            style: TextStyle(fontSize: mainFontSize, fontWeight: FontWeight.w900, color: theme.digitColor, height: 0.9)
          ),

          // Middle Line
          Positioned(
            top: size / 2, left: 0, right: 0, 
            child: Container(height: size * 0.008, color: Colors.black38)
          ),

          // Shine Effect
          Positioned(
            top: 0, left: 0, right: 0, height: size / 2,
            child: Container(decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, 
                  end: Alignment.bottomCenter, 
                  colors: [Colors.white10, Colors.transparent]
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.15)),
            )),
          ),

          // Bottom Left (AM/PM)
          if (bottomLeftLabel != null)
            Positioned(
              bottom: size * 0.06,
              left: size * 0.08,
              child: Text(
                bottomLeftLabel!,
                style: TextStyle(fontSize: cornerFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),

          // Bottom Right (Seconds)
          if (bottomRightLabel != null)
            Positioned(
              bottom: size * 0.06,
              right: size * 0.08,
              child: Text(
                bottomRightLabel!,
                style: TextStyle(fontSize: cornerFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),
        ],
      ),
    );
  }
}