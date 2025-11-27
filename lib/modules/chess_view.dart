import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../widgets/ flippable_card.dart';

class ClockDisplay extends StatefulWidget {
  final CustomTheme theme;
  final double scaleFactor;
  final double auxScaleFactor;

  const ClockDisplay({
    super.key, 
    required this.theme, 
    required this.scaleFactor, 
    required this.auxScaleFactor
  });
  
  @override
  State<ClockDisplay> createState() => _ClockDisplayState();
}

class _ClockDisplayState extends State<ClockDisplay> {
  late Timer _timer;
  late DateTime _now;
  
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }
  
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLandscape = constraints.maxWidth > constraints.maxHeight;
        
        String hour = DateFormat('hh').format(_now);
        String minute = DateFormat('mm').format(_now);
        String second = DateFormat('ss').format(_now);
        String amPm = DateFormat('a').format(_now).toUpperCase();
        
        String dateText = DateFormat('dd/MM/yy').format(_now); 
        String dayText = DateFormat('EEEE').format(_now); 

        double shortSide = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
        double baseSize = isLandscape ? shortSide * 0.75 : shortSide * 0.55; 
        double finalSize = baseSize * widget.scaleFactor;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: isLandscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlippableCard(
                        mainText: hour, 
                        topLabel: dateText,
                        bottomLeftLabel: amPm,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                      SizedBox(width: finalSize * 0.05),
                      FlippableCard(
                        mainText: minute, 
                        topLabel: dayText,
                        bottomRightLabel: second,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlippableCard(
                        mainText: hour, 
                        topLabel: dateText,
                        bottomLeftLabel: amPm,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                      SizedBox(height: finalSize * 0.05),
                      FlippableCard(
                        mainText: minute, 
                        topLabel: dayText,
                        bottomRightLabel: second,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}