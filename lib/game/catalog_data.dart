/// Pure data shared by the app and tool/gen_levels.dart (no Flutter imports).
/// Each world has four level packs of five levels (20 levels per world).
class WorldEntry {
  const WorldEntry(this.id, this.name, this.tagline, this.fallback, this.packs);
  final String id;
  final String name;
  final String tagline;
  final String fallback; // name of the built-in scene used until artwork exists
  final List<String> packs;

  String get art => 'assets/worlds/world_${(worldCatalog.indexOf(this) + 1).toString().padLeft(2, '0')}.jpg';
}

const worldCatalog = [
  WorldEntry('forest', 'Enchanted Forest', 'Ancient trees, fireflies and a hidden waterfall.', 'forest', ['Seedling', 'Sprout', 'Sapling', 'Grove']),
  WorldEntry('desert', 'Golden Desert', 'Endless dunes under a blazing sun.', 'desert', ['Dune', 'Oasis', 'Mirage', 'Pharaoh']),
  WorldEntry('coral', 'Coral Ocean', 'A sunlit reef full of colour.', 'ocean', ['Tide', 'Reef', 'Kelp', 'Lagoon']),
  WorldEntry('cosmic', 'Cosmic Galaxy', 'Nebulae, planets and a glowing galaxy.', 'nebula', ['Nebula', 'Pulsar', 'Quasar', 'Zenith']),
  WorldEntry('frozen', 'Frozen Kingdom', 'Ice cliffs and snowy peaks.', 'tundra', ['Flurry', 'Drift', 'Glacier', 'Icicle']),
  WorldEntry('volcanic', 'Volcanic Wasteland', 'Lava rivers under a smoky red sky.', 'volcano', ['Magma', 'Ash', 'Obsidian', 'Cinder']),
  WorldEntry('jungle', 'Lost Jungle Temple', 'Overgrown ruins hidden in the mist.', 'forest', ['Vine', 'Fern', 'Relic', 'Canopy']),
  WorldEntry('cyber', 'Neon Cyber City', 'Skyscrapers glowing in the night.', 'neon', ['Pixel', 'Combo', 'Glitch', 'Hologram']),
  WorldEntry('countryside', 'Sunny Countryside', 'Rolling hills, a red barn and a windmill.', 'sky', ['Meadow', 'Harvest', 'Windmill', 'Barn']),
  WorldEntry('candy', 'Candy Wonderland', 'Pastel hills and peppermint trees.', 'sky', ['Gumdrop', 'Sprinkle', 'Fudge', 'Lollipop']),
  WorldEntry('moonlit', 'Moonlit Forest', 'A huge moon over a quiet lake.', 'forest', ['Moonbeam', 'Lantern', 'Hollow', 'Twilight']),
  WorldEntry('autumn', 'Autumn Valley', 'Golden leaves and a winding river.', 'desert', ['Maple', 'Russet', 'Hearth', 'Rustle']),
  WorldEntry('ruins', 'Ancient Ruins', 'Colossal pillars and broken arches.', 'peak', ['Pillar', 'Arch', 'Mosaic', 'Obelisk']),
  WorldEntry('tropical', 'Tropical Paradise', 'White sand and turquoise water.', 'sky', ['Palm', 'Cove', 'Breeze', 'Sandbar']),
  WorldEntry('crystal', 'Crystal Caverns', 'Giant glowing gemstones underground.', 'cavern', ['Geode', 'Facet', 'Prism', 'Lumen']),
  WorldEntry('fairytale', 'Fairytale Kingdom', 'Castles, bridges and flowing waterfalls.', 'sky', ['Turret', 'Drawbridge', 'Banner', 'Courtyard']),
  WorldEntry('treasure', 'Treasure Cavern', 'A chamber glittering with gold.', 'volcano', ['Ingot', 'Nugget', 'Hoard', 'Vault']),
  WorldEntry('sakura', 'Sakura Mountains', 'Cherry blossoms and torii gates.', 'peak', ['Blossom', 'Torii', 'Petal', 'Zen']),
  WorldEntry('deepsea', 'Deep Sea Glow', 'Giant jellyfish in the dark blue.', 'ocean', ['Jelly', 'Glow', 'Abyss', 'Trench']),
  WorldEntry('skyislands', 'Floating Sky Islands', 'Islands drifting above the clouds.', 'sky', ['Cloud', 'Zephyr', 'Gale', 'Aerie']),
];
