import 'package:flutter/material.dart';

// Warm "wooden sign" look: cocoa panels, cream text, amber accents, flat shapes.
const lantern = Color(0xFFF6A93B); // amber accent for selection/highlights
const parchment = Color(0xFFFBF1DC); // cream text
const cocoa = Color(0xFF3B2A22); // panel colour
const cocoaDeep = Color(0xFF241810); // hard shadow / track
const cocoaEdge = Color(0xFF7A5640); // panel rim
const leafGreen = Color(0xFF6DBB5A);
const woodLight = Color(0xFFB07A44);
const woodDark = Color(0xFF6B4423);
const holeColor = Color(0xFF3A2312);

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: lantern,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF2B1D17),
      textTheme: const TextTheme().apply(
        bodyColor: parchment,
        displayColor: parchment,
      ),
    );

const displayFont = TextStyle(
  fontFamily: 'Nunito',
  fontWeight: FontWeight.w800,
  color: parchment,
  letterSpacing: -0.2,
  height: 1.15,
);

bool reduceMotion(BuildContext c) => MediaQuery.of(c).disableAnimations;
