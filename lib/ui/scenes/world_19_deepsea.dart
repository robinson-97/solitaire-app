import 'package:flutter/material.dart';
import 'kit.dart';

// Deep Sea Glow: placeholder until the real scene is drawn.
SceneSpec deepseaScene() => SceneSpec(layers: [
      Layer.still((c, s) => fillSky(c, s, const [Color(0xFF1B2A5A), Color(0xFF4A5FA8), Color(0xFFB9A8E8)])),
    ]);
