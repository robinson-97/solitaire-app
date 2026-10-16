import 'package:flutter/material.dart';

// Dark neon-night look: deep navy panels, cyan neon accents, crisp white text.
const lantern = Color(0xFF35F0FF); // neon cyan accent for selection/highlights
const neonPink = Color(0xFFFF3DB4);
const parchment = Color(0xFFF2F6FF); // text
const cocoa = Color(0xFF11153A); // panel colour
const cocoaDeep = Color(0xFF04061A); // hard shadow / track
const cocoaEdge = Color(0xFF2E3C8C); // panel rim
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
      scaffoldBackgroundColor: const Color(0xFF070A1C),
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
