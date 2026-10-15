import 'package:flutter/material.dart';

const lantern = Color(0xFFFFB347); // amber accent for selection/highlights
const parchment = Color(0xFFF6F1E4);
const woodLight = Color(0xFFB07A44);
const woodDark = Color(0xFF6B4423);
const holeColor = Color(0xFF3A2312);

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: lantern,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1230),
      textTheme: const TextTheme().apply(
        bodyColor: parchment,
        displayColor: parchment,
      ),
    );

const displayFont = TextStyle(
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w600,
  color: parchment,
  letterSpacing: -0.3,
  height: 1.15,
);

bool reduceMotion(BuildContext c) => MediaQuery.of(c).disableAnimations;
