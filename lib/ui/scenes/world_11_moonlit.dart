import 'package:flutter/material.dart';
import 'kit.dart';

// Moonlit Forest: placeholder until the real scene is drawn.
SceneSpec moonlitScene() => SceneSpec(layers: [
      Layer.still((c, s) => fillSky(c, s, const [Color(0xFF1B2A5A), Color(0xFF4A5FA8), Color(0xFFB9A8E8)])),
    ]);
