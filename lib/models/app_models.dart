import 'dart:io';
import 'package:flutter/material.dart';

enum AppMode { clock, stopwatch, chess }

class CustomTheme {
  File? backgroundImage;
  Color cardColor;
  Color digitColor;

  CustomTheme({
    this.backgroundImage,
    // Your requested default colors
    required this.cardColor,  
    required this.digitColor, 
  });
}