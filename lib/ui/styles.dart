import 'package:flutter/material.dart';
import 'fx.dart';

/// Peg and board looks. Which ones are unlocked is decided in unlocks.dart.
enum PegKind {
  wood, glass, moon, ember, crystal, star, frost, mushroom,
  soccer, basketball, tennis, baseball, billiard, golf,
  pixel, disco, vinyl, smiley, donut, planet, cookie,
  material,
  aurora, galaxy, tide, clockwork, storm, plasma, koi, lantern, radar, peppermint,
}

enum BoardKind { wood, stone, marble, crystal, rune, lava, pitch, neon, sakura, galaxy, ocean, candy, aurora }

/// A fully shader-drawn material (see shaders/peg.frag).
class MaterialSpec {
  const MaterialSpec(this.mode, this.c1, this.c2, this.c3);
  final double mode; // 0 marble, 1 glass, 2 metal, 3 lava, 4 crystal, 5 wood, 6 pearl
  final Color c1, c2, c3;
}

class PegTheme {
  const PegTheme({
    required this.id,
    required this.name,
    required this.kind,
    required this.colors,
    required this.fx,
    required this.category,
    this.glow = const Color(0xFFFFB347),
    this.glowAlpha = 0,
    this.fxColor,
    this.shine = 0.55,
    this.mat,
  });
  final String id;
  final String name;
  final PegKind kind;
  final List<Color> colors; // highlight -> shadow
  final FxKind fx; // hop trail and landing effect
  final String category;
  final Color glow;
  final double glowAlpha;
  final Color? fxColor;
  final double shine; // how reflective the studio light overlay is
  final MaterialSpec? mat;
}

const pegThemes = [
  // ---- Nature & magic
  PegTheme(id: 'acorn', name: 'Acorn Wood', kind: PegKind.wood, category: 'Nature & magic', fx: FxKind.none,
      colors: [Color(0xFFFFE3A8), Color(0xFFE9A04A), Color(0xFFA85F1E), Color(0xFF4A230A)]),
  PegTheme(id: 'firefly', name: 'Firefly Glass', kind: PegKind.glass, category: 'Nature & magic', fx: FxKind.firefly,
      colors: [Color(0xFFEFFFD0), Color(0xFF8CF0A8), Color(0xFF1E9A78), Color(0xFF0B4A3A)],
      glow: Color(0xFFB6FF6A), glowAlpha: 0.55),
  PegTheme(id: 'moonstone', name: 'Moonstone', kind: PegKind.moon, category: 'Nature & magic', fx: FxKind.moon,
      colors: [Color(0xFFFFFFFF), Color(0xFFDDE8FF), Color(0xFF93A8E6), Color(0xFF47579A)],
      glow: Color(0xFF9DB9FF), glowAlpha: 0.4),
  PegTheme(id: 'mushroom', name: 'Mushroom', kind: PegKind.mushroom, category: 'Nature & magic', fx: FxKind.puff,
      colors: [Color(0xFFFFF6E0), Color(0xFFF2D9B0), Color(0xFFC79A62), Color(0xFF6E4423)],
      fxColor: Color(0xFFE6F0B0)),
  PegTheme(id: 'geode', name: 'Geode Crystal', kind: PegKind.crystal, category: 'Nature & magic', fx: FxKind.crystal,
      colors: [Color(0xFFF4E6FF), Color(0xFFB48CFF), Color(0xFF5B3FC4), Color(0xFF1C0F55)],
      glow: Color(0xFF8E7CFF), glowAlpha: 0.55),
  PegTheme(id: 'ember', name: 'Ember Crystal', kind: PegKind.ember, category: 'Nature & magic', fx: FxKind.ember,
      colors: [Color(0xFFFFF0A0), Color(0xFFFF9A2E), Color(0xFFD4380D), Color(0xFF5A0F05)],
      glow: Color(0xFFFF5A1F), glowAlpha: 0.6),
  PegTheme(id: 'starlight', name: 'Starlight Gold', kind: PegKind.star, category: 'Nature & magic', fx: FxKind.star,
      colors: [Color(0xFFFFFBDC), Color(0xFFFFD866), Color(0xFFC9871A), Color(0xFF5E3A06)],
      glow: Color(0xFFFFE27A), glowAlpha: 0.6),
  PegTheme(id: 'frost', name: 'Frost Pearl', kind: PegKind.frost, category: 'Nature & magic', fx: FxKind.frost,
      colors: [Color(0xFFFFFFFF), Color(0xFFD2F0FF), Color(0xFF7FC4EA), Color(0xFF2D6EA3)],
      glow: Color(0xFF9BE3FF), glowAlpha: 0.45),
  // ---- Sweet
  PegTheme(id: 'cookie', name: 'Choc Chip Cookie', kind: PegKind.cookie, category: 'Sweet treats', fx: FxKind.crumbs,
      colors: [Color(0xFFF6D9A0), Color(0xFFDDB070), Color(0xFFB07A3A), Color(0xFF5E3A14)],
      fxColor: Color(0xFFB07A3A)),
  PegTheme(id: 'donut', name: 'Sprinkle Donut', kind: PegKind.donut, category: 'Sweet treats', fx: FxKind.sprinkles,
      colors: [Color(0xFFF7DDB0), Color(0xFFE0AA68), Color(0xFFB07A3A), Color(0xFF5E3A14)]),
  // ---- Sports
  PegTheme(id: 'soccer', name: 'Soccer Ball', kind: PegKind.soccer, category: 'Sports', fx: FxKind.confetti,
      colors: [Color(0xFFFFFFFF), Color(0xFFF2F2F2), Color(0xFFC9C9C9), Color(0xFF8A8A8A)]),
  PegTheme(id: 'basketball', name: 'Basketball', kind: PegKind.basketball, category: 'Sports', fx: FxKind.puff,
      colors: [Color(0xFFFFB070), Color(0xFFF07F2A), Color(0xFFC25A12), Color(0xFF6A2E08)],
      fxColor: Color(0xFFFF9A4A)),
  PegTheme(id: 'tennis', name: 'Tennis Ball', kind: PegKind.tennis, category: 'Sports', fx: FxKind.puff,
      colors: [Color(0xFFF6FF8A), Color(0xFFD6EC38), Color(0xFF9DBA1A), Color(0xFF566A06)],
      fxColor: Color(0xFFE2F06A)),
  PegTheme(id: 'baseball', name: 'Baseball', kind: PegKind.baseball, category: 'Sports', fx: FxKind.dust,
      colors: [Color(0xFFFFFFFF), Color(0xFFF3EFE6), Color(0xFFC9C2B0), Color(0xFF8A8270)]),
  PegTheme(id: 'billiard', name: '8-Ball', kind: PegKind.billiard, category: 'Sports', fx: FxKind.puff,
      colors: [Color(0xFF6A6A72), Color(0xFF2A2A30), Color(0xFF111116), Color(0xFF000000)],
      fxColor: Color(0xFF7FB6FF)),
  PegTheme(id: 'golf', name: 'Golf Ball', kind: PegKind.golf, category: 'Sports', fx: FxKind.puff,
      colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FA), Color(0xFFCBD3DB), Color(0xFF8E99A4)],
      fxColor: Color(0xFFF2F2F2)),
  // ---- Pop & arcade
  PegTheme(id: 'pixel', name: 'Pixel Coin', kind: PegKind.pixel, category: 'Pop & arcade', fx: FxKind.pixel,
      colors: [Color(0xFFFFF1A0), Color(0xFFFFD23A), Color(0xFFD79A0E), Color(0xFF7A4D03)],
      glow: Color(0xFFFFD23A), glowAlpha: 0.35),
  PegTheme(id: 'disco', name: 'Disco Ball', kind: PegKind.disco, category: 'Pop & arcade', fx: FxKind.confetti,
      colors: [Color(0xFFFFFFFF), Color(0xFFD6DCE8), Color(0xFF9AA4BA), Color(0xFF4A526A)],
      glow: Color(0xFFFF6AD5), glowAlpha: 0.4),
  PegTheme(id: 'vinyl', name: 'Vinyl Record', kind: PegKind.vinyl, category: 'Pop & arcade', fx: FxKind.note,
      colors: [Color(0xFF4A4A52), Color(0xFF24242A), Color(0xFF111114), Color(0xFF050507)],
      fxColor: Color(0xFFFF8AD0)),
  PegTheme(id: 'smiley', name: 'Smiley', kind: PegKind.smiley, category: 'Pop & arcade', fx: FxKind.heart,
      colors: [Color(0xFFFFF6A0), Color(0xFFFFE03A), Color(0xFFE3B410), Color(0xFF8A6A04)]),
  // ---- Space
  // ---- Premium materials (fully shader-lit)
  PegTheme(id: 'marble', name: 'White Marble', kind: PegKind.material, category: 'Premium materials', fx: FxKind.moon,
      colors: [Color(0xFFF4F1EA), Color(0xFFB9B4AA), Color(0xFF6A665E), Color(0xFF2B2B33)],
      mat: MaterialSpec(0, Color(0xFFF4F1EA), Color(0xFFB9B4AA), Color(0xFF2B2B33))),
  PegTheme(id: 'onyx', name: 'Gilded Onyx', kind: PegKind.material, category: 'Premium materials', fx: FxKind.star,
      colors: [Color(0xFF3A4660), Color(0xFF1A1F2B), Color(0xFF0E121A), Color(0xFF05070A)],
      glow: Color(0xFFE6C97A), glowAlpha: 0.25,
      mat: MaterialSpec(0, Color(0xFF1A1F2B), Color(0xFF3A4660), Color(0xFFE6C97A))),
  PegTheme(id: 'gold', name: 'Solid Gold', kind: PegKind.material, category: 'Premium materials', fx: FxKind.star,
      colors: [Color(0xFFFFE9A0), Color(0xFFE0A93A), Color(0xFFA06A10), Color(0xFF4A2D04)],
      glow: Color(0xFFFFD866), glowAlpha: 0.3,
      mat: MaterialSpec(2, Color(0xFFFFE9A0), Color(0xFFC9871A), Color(0xFF000000))),
  PegTheme(id: 'magma', name: 'Magma Core', kind: PegKind.material, category: 'Premium materials', fx: FxKind.ember,
      colors: [Color(0xFFFFC27A), Color(0xFFFF6A1E), Color(0xFF7A1E0C), Color(0xFF1C0F0C)],
      glow: Color(0xFFFF5A1F), glowAlpha: 0.55,
      mat: MaterialSpec(3, Color(0xFFFF6A1E), Color(0xFFFFC27A), Color(0xFF1C0F0C))),
  PegTheme(id: 'amethyst', name: 'Amethyst', kind: PegKind.material, category: 'Premium materials', fx: FxKind.crystal,
      colors: [Color(0xFFE6D4FF), Color(0xFFB48CFF), Color(0xFF6A45D8), Color(0xFF241060)],
      glow: Color(0xFF9B7CFF), glowAlpha: 0.45,
      mat: MaterialSpec(4, Color(0xFFB48CFF), Color(0xFF6A45D8), Color(0xFF000000))),
  PegTheme(id: 'pearl', name: 'Opal Pearl', kind: PegKind.material, category: 'Premium materials', fx: FxKind.moon,
      colors: [Color(0xFFFFFFFF), Color(0xFFF2F0FA), Color(0xFFC9B8E8), Color(0xFF6A6A9A)],
      glow: Color(0xFFD7C8FF), glowAlpha: 0.3,
      mat: MaterialSpec(6, Color(0xFFF2F0FA), Color(0xFF000000), Color(0xFF000000))),
  // ---- Living lights (animated)
  PegTheme(id: 'aurora', name: 'Aurora Orb', kind: PegKind.aurora, category: 'Living lights', fx: FxKind.frost,
      colors: [Color(0xFFB8FFE0), Color(0xFF1E6A78), Color(0xFF123E58), Color(0xFF071A2E)], glow: Color(0xFF6BFFB0), glowAlpha: 0.5),
  PegTheme(id: 'galaxy', name: 'Galaxy Marble', kind: PegKind.galaxy, category: 'Living lights', fx: FxKind.star,
      colors: [Color(0xFFE6D8FF), Color(0xFF3A2A8A), Color(0xFF1C1250), Color(0xFF080420)], glow: Color(0xFFB59BFF), glowAlpha: 0.5),
  PegTheme(id: 'tide', name: 'Tide Globe', kind: PegKind.tide, category: 'Living lights', fx: FxKind.puff, fxColor: Color(0xFFBDEBFF),
      colors: [Color(0xFFD6F4FF), Color(0xFF3FA6E0), Color(0xFF1C6AB0), Color(0xFF0A3668)], glow: Color(0xFF7FD6FF), glowAlpha: 0.35),
  PegTheme(id: 'clockwork', name: 'Clockwork Gear', kind: PegKind.clockwork, category: 'Living lights', fx: FxKind.dust,
      colors: [Color(0xFFFFE6B0), Color(0xFFC9923A), Color(0xFF8A5A1E), Color(0xFF3A230A)], glow: Color(0xFFFFC46B), glowAlpha: 0.2),
  PegTheme(id: 'storm', name: 'Storm Orb', kind: PegKind.storm, category: 'Living lights', fx: FxKind.crystal,
      colors: [Color(0xFFD6DCEE), Color(0xFF59607A), Color(0xFF353A52), Color(0xFF12141F)], glow: Color(0xFFBFD0FF), glowAlpha: 0.4),
  PegTheme(id: 'plasma', name: 'Plasma Ball', kind: PegKind.plasma, category: 'Living lights', fx: FxKind.crystal,
      colors: [Color(0xFFFFD6FF), Color(0xFF8A2AC8), Color(0xFF4A1488), Color(0xFF12052E)], glow: Color(0xFFE05AFF), glowAlpha: 0.6),
  PegTheme(id: 'koi', name: 'Koi Pond', kind: PegKind.koi, category: 'Living lights', fx: FxKind.puff, fxColor: Color(0xFFBFF0F0),
      colors: [Color(0xFFD6FFF4), Color(0xFF3CB0A8), Color(0xFF1E7A82), Color(0xFF0A3A48)], glow: Color(0xFF7FFFE0), glowAlpha: 0.25),
  PegTheme(id: 'lantern', name: 'Paper Lantern', kind: PegKind.lantern, category: 'Living lights', fx: FxKind.ember,
      colors: [Color(0xFFFFE0A0), Color(0xFFE5482E), Color(0xFFB02A1E), Color(0xFF4A0E08)], glow: Color(0xFFFF9A4A), glowAlpha: 0.55),
  PegTheme(id: 'radar', name: 'Radar Pulse', kind: PegKind.radar, category: 'Living lights', fx: FxKind.pixel,
      colors: [Color(0xFFC8FFD6), Color(0xFF1E8A4A), Color(0xFF0E5A30), Color(0xFF031A0C)], glow: Color(0xFF5AFF9A), glowAlpha: 0.4),
  PegTheme(id: 'peppermint', name: 'Peppermint Swirl', kind: PegKind.peppermint, category: 'Living lights', fx: FxKind.sprinkles,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFE6EC), Color(0xFFE88AA0), Color(0xFF8A2A48)]),
  PegTheme(id: 'planet', name: 'Ringed Planet', kind: PegKind.planet, category: 'Space', fx: FxKind.star,
      colors: [Color(0xFFFFE9C0), Color(0xFFF3B66A), Color(0xFFC2742E), Color(0xFF6A3410)],
      glow: Color(0xFFFFC27A), glowAlpha: 0.3),
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
  final Color accent; // glow for veins / crystals / lines
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
  BoardTheme('pitch', 'Match Pitch', BoardKind.pitch,
      [Color(0xFF4FAE4A), Color(0xFF3B9440), Color(0xFF2A7030)],
      Color(0xFF184A1E), Color(0xFFFFFFFF), Color(0xFF1F5A24), Color(0xFF0F3414),
      Color(0xFF2E7A33), Color(0xFFFFFFFF)),
  BoardTheme('neon', 'Neon Grid', BoardKind.neon,
      [Color(0xFF241A5A), Color(0xFF160F3C), Color(0xFF0A0722)],
      Color(0xFF050313), Color(0xFFFF3DB4), Color(0xFF120A33), Color(0xFF05030F),
      Color(0xFF2B1F7A), Color(0xFF35F0FF)),
  BoardTheme('sakura', 'Sakura Blossom', BoardKind.sakura,
      [Color(0xFFF8CFDC), Color(0xFFF0A6BD), Color(0xFFC9708F)],
      Color(0xFF8F4A63), Color(0xFFFFFFFF), Color(0xFF7A3048), Color(0xFF3D1424),
      Color(0xFFFFD6E4), Color(0xFFFFB7D0)),
  BoardTheme('galaxy', 'Galaxy Slate', BoardKind.galaxy,
      [Color(0xFF3A2A7A), Color(0xFF22164F), Color(0xFF120B30)],
      Color(0xFF08051A), Color(0xFFB9A6FF), Color(0xFF0B0724), Color(0xFF030212),
      Color(0xFF5B3FC4), Color(0xFFC9B8FF)),
  BoardTheme('ocean', 'Tidepool', BoardKind.ocean,
      [Color(0xFF56BDEE), Color(0xFF2C8FD0), Color(0xFF1A5FA0)],
      Color(0xFF0E3C6A), Color(0xFFFFFFFF), Color(0xFF12406E), Color(0xFF06203C),
      Color(0xFF6BE0C0), Color(0xFF9BE8FF)),
  BoardTheme('candy', 'Candy Cane', BoardKind.candy,
      [Color(0xFFFFD6E4), Color(0xFFFF9DBE), Color(0xFFE0628F)],
      Color(0xFF9A2F5C), Color(0xFFFFFFFF), Color(0xFF8E2A54), Color(0xFF4A1030),
      Color(0xFFFFFFFF), Color(0xFFFFFFFF)),
  BoardTheme('aurora', 'Aurora Ice', BoardKind.aurora,
      [Color(0xFF2B4A7A), Color(0xFF1B3256), Color(0xFF0F1E3A)],
      Color(0xFF070F22), Color(0xFF7CFFD0), Color(0xFF0A1630), Color(0xFF040A18),
      Color(0xFF7CFFD0), Color(0xFF7CFFD0)),
];

BoardTheme boardThemeById(String id) =>
    boardThemes.firstWhere((t) => t.id == id, orElse: () => boardThemes.first);
