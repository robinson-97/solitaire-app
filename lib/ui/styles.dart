import 'package:flutter/material.dart';
import 'fx.dart';

/// Peg and board looks. Unlock rules come with the Collection screen; for now
/// everything is selectable so the looks can be tested.
enum PegKind { wood, glass, moon, ember, crystal, star, frost, mushroom }
enum BoardKind { wood, stone, marble, crystal, rune, lava }

class PegTheme {
  const PegTheme(this.id, this.name, this.kind, this.colors, this.glow,
      this.glowAlpha, this.requirement, this.fx);
  final String id;
  final String name;
  final PegKind kind;
  final List<Color> colors; // highlight -> shadow
  final Color glow;
  final double glowAlpha;
  final String requirement;
  final FxKind fx; // hop trail and landing effect
}

const pegThemes = [
  PegTheme('acorn', 'Acorn Wood', PegKind.wood,
      [Color(0xFFFFE3A8), Color(0xFFE9A04A), Color(0xFFA85F1E), Color(0xFF4A230A)],
      Color(0xFFFFB347), 0.0, 'Start', FxKind.none),
  PegTheme('firefly', 'Firefly Glass', PegKind.glass,
      [Color(0xFFEFFFD0), Color(0xFF8CF0A8), Color(0xFF1E9A78), Color(0xFF0B4A3A)],
      Color(0xFFB6FF6A), 0.55, 'Score 400 on Sprout 5', FxKind.firefly),
  PegTheme('geode', 'Geode Crystal', PegKind.crystal,
      [Color(0xFFF4E6FF), Color(0xFFB48CFF), Color(0xFF5B3FC4), Color(0xFF1C0F55)],
      Color(0xFF8E7CFF), 0.55, 'Score 450 on Facet 5', FxKind.crystal),
  PegTheme('moonstone', 'Moonstone', PegKind.moon,
      [Color(0xFFFFFFFF), Color(0xFFDDE8FF), Color(0xFF93A8E6), Color(0xFF47579A)],
      Color(0xFF9DB9FF), 0.4, 'Score 450 on Sapling 5', FxKind.moon),
  PegTheme('ember', 'Ember Crystal', PegKind.ember,
      [Color(0xFFFFF0A0), Color(0xFFFF9A2E), Color(0xFFD4380D), Color(0xFF5A0F05)],
      Color(0xFFFF5A1F), 0.6, 'Score 500 on Prism 5', FxKind.ember),
  PegTheme('starlight', 'Starlight Gold', PegKind.star,
      [Color(0xFFFFFBDC), Color(0xFFFFD866), Color(0xFFC9871A), Color(0xFF5E3A06)],
      Color(0xFFFFE27A), 0.6, 'Score 600 on Comet 5', FxKind.star),
  PegTheme('frost', 'Frost Pearl', PegKind.frost,
      [Color(0xFFFFFFFF), Color(0xFFD2F0FF), Color(0xFF7FC4EA), Color(0xFF2D6EA3)],
      Color(0xFF9BE3FF), 0.45, 'Score 520 on Nova 5', FxKind.frost),
  PegTheme('mushroom', 'Mushroom', PegKind.mushroom,
      [Color(0xFFFFF6E0), Color(0xFFF2D9B0), Color(0xFFC79A62), Color(0xFF6E4423)],
      Color(0xFFE6F0B0), 0.0, 'Score 450 on Grove 5', FxKind.spore),
];

PegTheme pegThemeById(String id) =>
    pegThemes.firstWhere((t) => t.id == id, orElse: () => pegThemes.first);

class BoardTheme {
  const BoardTheme(this.id, this.name, this.kind, this.body, this.side, this.grain,
      this.holeInner, this.holeOuter, this.moss, this.accent);
  final String id;
  final String name;
  final BoardKind kind;
  final List<Color> body; // light -> dark
  final Color side; // visible thickness
  final Color grain;
  final Color holeInner;
  final Color holeOuter;
  final Color moss;
  final Color accent; // glow for veins / crystals
}

const boardThemes = [
  BoardTheme('oak', 'Old Oak', BoardKind.wood,
      [Color(0xFFC48A52), Color(0xFF9A6234), Color(0xFF6B4423)],
      Color(0xFF4A2D14), Color(0xFF3B200C), Color(0xFF4A2A14), Color(0xFF1B0D05),
      Color(0xFF3F7A3A), Color(0xFFFFB347)),
  BoardTheme('mossy', 'Mossy Stone', BoardKind.stone,
      [Color(0xFF98A39E), Color(0xFF6F7C77), Color(0xFF47524E)],
      Color(0xFF2B3330), Color(0xFF1E2724), Color(0xFF2F3A36), Color(0xFF0E1412),
      Color(0xFF4FA050), Color(0xFF9CFF9C)),
  BoardTheme('crystal', 'Crystal Slab', BoardKind.crystal,
      [Color(0xFF5A4A9C), Color(0xFF3A2D78), Color(0xFF1F1648)],
      Color(0xFF120B30), Color(0xFFB9A6FF), Color(0xFF1C1244), Color(0xFF080420),
      Color(0xFF38D6E0), Color(0xFF7CF0FF)),
  BoardTheme('rune', 'Rune Stone', BoardKind.rune,
      [Color(0xFF5B6370), Color(0xFF3F4652), Color(0xFF272C36)],
      Color(0xFF161A21), Color(0xFF8FD6FF), Color(0xFF20252E), Color(0xFF0B0D12),
      Color(0xFF3F7A6A), Color(0xFF6FE3FF)),
  BoardTheme('lava', 'Lava Rock', BoardKind.lava,
      [Color(0xFF4A4244), Color(0xFF2E2729), Color(0xFF1A1617)],
      Color(0xFF0F0B0B), Color(0xFFFF7A2E), Color(0xFF1D1414), Color(0xFF080505),
      Color(0xFF5A1F0F), Color(0xFFFF7A2E)),
  BoardTheme('marble', 'Frost Marble', BoardKind.marble,
      [Color(0xFFEAF1FA), Color(0xFFBFCCE0), Color(0xFF8798B5)],
      Color(0xFF5D6C88), Color(0xFF5B79B0), Color(0xFF6C7EA0), Color(0xFF26324A),
      Color(0xFFB8E6FF), Color(0xFFBFE6FF)),
];

BoardTheme boardThemeById(String id) =>
    boardThemes.firstWhere((t) => t.id == id, orElse: () => boardThemes.first);
