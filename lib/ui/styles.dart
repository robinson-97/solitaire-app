import 'package:flutter/material.dart';

/// Peg and board looks. Unlock rules come with the Collection screen; for now
/// everything is selectable so the looks can be tested.
enum PegKind { wood, glass, moon, ember }

class PegTheme {
  const PegTheme(this.id, this.name, this.kind, this.colors, this.glow,
      this.glowAlpha, this.requirement);
  final String id;
  final String name;
  final PegKind kind;
  final List<Color> colors; // highlight -> shadow
  final Color glow;
  final double glowAlpha;
  final String requirement;
}

const pegThemes = [
  PegTheme('acorn', 'Acorn Wood', PegKind.wood,
      [Color(0xFFFFE3A8), Color(0xFFE9A04A), Color(0xFFA85F1E), Color(0xFF4A230A)],
      Color(0xFFFFB347), 0.0, 'Start'),
  PegTheme('firefly', 'Firefly Glass', PegKind.glass,
      [Color(0xFFEFFFD0), Color(0xFF8CF0A8), Color(0xFF1E9A78), Color(0xFF0B4A3A)],
      Color(0xFFB6FF6A), 0.55, 'Best score 300'),
  PegTheme('moonstone', 'Moonstone', PegKind.moon,
      [Color(0xFFFFFFFF), Color(0xFFDDE8FF), Color(0xFF93A8E6), Color(0xFF47579A)],
      Color(0xFF9DB9FF), 0.4, 'Best score 500'),
  PegTheme('ember', 'Ember Crystal', PegKind.ember,
      [Color(0xFFFFF0A0), Color(0xFFFF9A2E), Color(0xFFD4380D), Color(0xFF5A0F05)],
      Color(0xFFFF5A1F), 0.6, 'Best score 700'),
];

PegTheme pegThemeById(String id) =>
    pegThemes.firstWhere((t) => t.id == id, orElse: () => pegThemes.first);

class BoardTheme {
  const BoardTheme(this.id, this.name, this.body, this.side, this.grain,
      this.holeInner, this.holeOuter, this.moss, this.stone, this.requirement);
  final String id;
  final String name;
  final List<Color> body; // light -> dark
  final Color side; // visible thickness
  final Color grain;
  final Color holeInner;
  final Color holeOuter;
  final Color moss;
  final bool stone;
  final String requirement;
}

const boardThemes = [
  BoardTheme('oak', 'Old Oak',
      [Color(0xFFC48A52), Color(0xFF9A6234), Color(0xFF6B4423)],
      Color(0xFF4A2D14), Color(0xFF3B200C), Color(0xFF4A2A14), Color(0xFF1B0D05),
      Color(0xFF3F7A3A), false, 'Start'),
  BoardTheme('mossy', 'Mossy Stone',
      [Color(0xFF98A39E), Color(0xFF6F7C77), Color(0xFF47524E)],
      Color(0xFF2B3330), Color(0xFF1E2724), Color(0xFF2F3A36), Color(0xFF0E1412),
      Color(0xFF4FA050), true, '1,000 total points'),
];

BoardTheme boardThemeById(String id) =>
    boardThemes.firstWhere((t) => t.id == id, orElse: () => boardThemes.first);
