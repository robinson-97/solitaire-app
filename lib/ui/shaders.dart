import 'dart:ui' as ui;

/// Fragment shaders for 3D-lit pegs. If a shader fails to load (very old
/// device), pegs quietly fall back to the flat artwork.
class Gfx {
  static ui.FragmentProgram? gloss;
  static ui.FragmentProgram? material;

  static Future<void> init() async {
    try {
      gloss = await ui.FragmentProgram.fromAsset('shaders/gloss.frag');
      material = await ui.FragmentProgram.fromAsset('shaders/peg.frag');
    } catch (_) {
      gloss = null;
      material = null;
    }
  }
}
