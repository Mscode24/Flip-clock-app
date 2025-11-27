import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import 'digit_card.dart';

class FlippableCard extends StatelessWidget {
  final String mainText;
  final double size;
  final CustomTheme theme;
  final String? topLabel;
  final String? bottomLeftLabel;
  final String? bottomRightLabel;
  final double auxScale;

  const FlippableCard({
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450), 
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(mainText) != child?.key);
            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            tilt *= isUnder ? -1.0 : 1.0;
            final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
            
            return Transform(
              transform: Matrix4.rotationX(value)..setEntry(3, 2, 0.001), 
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: DigitCard(
        key: ValueKey(mainText), 
        mainText: mainText,
        size: size,
        theme: theme,
        topLabel: topLabel,
        bottomLeftLabel: bottomLeftLabel,
        bottomRightLabel: bottomRightLabel,
        auxScale: auxScale,
      ),
    );
  }
}