import 'dart:io';
import 'package:flutter/material.dart';

enum AppMode { clock, stopwatch, chess }

class CustomTheme {
  File? backgroundImage;
  Color cardColor;
  Color digitColor;
  double cardOpacity; // NEW: Controls transparency

  CustomTheme({
    this.backgroundImage,
    required this.cardColor,
    required this.digitColor,
    this.cardOpacity = 1.0, // Default 1.0 (Solid)
  });
}