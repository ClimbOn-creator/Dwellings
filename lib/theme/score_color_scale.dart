import 'package:flutter/material.dart';

const scoreRed = Color(0xFFD62828);
const scoreOrange = Color(0xFFF28C28);
const scoreGreen = Color(0xFF168A52);

Color scoreColor(int value) {
  final score = value.clamp(1, 99);
  if (score <= 50) {
    return Color.lerp(scoreRed, scoreOrange, (score - 1) / 49)!;
  }
  return Color.lerp(scoreOrange, scoreGreen, (score - 50) / 49)!;
}
