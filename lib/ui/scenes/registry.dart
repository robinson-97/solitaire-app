import 'package:flutter/material.dart';
import 'kit.dart';
import 'world_01_forest.dart';
import 'world_02_desert.dart';
import 'world_03_coral.dart';
import 'world_04_cosmic.dart';
import 'world_05_frozen.dart';
import 'world_06_volcanic.dart';
import 'world_07_jungle.dart';
import 'world_08_cyber.dart';
import 'world_09_countryside.dart';
import 'world_10_candy.dart';
import 'world_11_moonlit.dart';
import 'world_12_autumn.dart';
import 'world_13_ruins.dart';
import 'world_14_tropical.dart';
import 'world_15_crystal.dart';
import 'world_16_fairytale.dart';
import 'world_17_treasure.dart';
import 'world_18_sakura.dart';
import 'world_19_deepsea.dart';
import 'world_20_skyislands.dart';

typedef SceneBuilder = SceneSpec Function();

/// World id (see game/catalog_data.dart) -> its animated scene.
final Map<String, SceneBuilder> _builders = {
  'forest': forestScene,
  'desert': desertScene,
  'coral': coralScene,
  'cosmic': cosmicScene,
  'frozen': frozenScene,
  'volcanic': volcanicScene,
  'jungle': jungleScene,
  'cyber': cyberScene,
  'countryside': countrysideScene,
  'candy': candyScene,
  'moonlit': moonlitScene,
  'autumn': autumnScene,
  'ruins': ruinsScene,
  'tropical': tropicalScene,
  'crystal': crystalScene,
  'fairytale': fairytaleScene,
  'treasure': treasureScene,
  'sakura': sakuraScene,
  'deepsea': deepseaScene,
  'skyislands': skyislandsScene,
};

final Map<String, SceneSpec> _cache = {};

SceneSpec sceneFor(String id) => _cache.putIfAbsent(id, () => (_builders[id] ?? _placeholder)());

SceneSpec _placeholder() => SceneSpec(layers: [
      Layer.still((c, s) => fillSky(c, s, const [Color(0xFF1B2A5A), Color(0xFF4A5FA8), Color(0xFFB9A8E8)])),
    ]);
