/// Pure data shared by the app and tool/gen_levels.dart (no Flutter imports).
/// Each world has four level packs of five levels (20 levels per world).
class WorldEntry {
  const WorldEntry(this.id, this.name, this.tagline, this.packs);
  final String id;
  final String name;
  final String tagline;
  final List<String> packs;
}

const worldCatalog = [
  WorldEntry('forest', 'Enchanted Forest', 'Ancient trees, fireflies and a hidden waterfall.', ['Seedling', 'Sprout', 'Sapling', 'Grove']),
  WorldEntry('desert', 'Golden Desert', 'Endless dunes under a blazing sun.', ['Dune', 'Oasis', 'Mirage', 'Pharaoh']),
  WorldEntry('coral', 'Coral Ocean', 'A sunlit reef full of colour.', ['Tide', 'Reef', 'Kelp', 'Lagoon']),
  WorldEntry('cosmic', 'Cosmic Galaxy', 'Nebulae, planets and a glowing galaxy.', ['Nebula', 'Pulsar', 'Quasar', 'Zenith']),
  WorldEntry('frozen', 'Frozen Kingdom', 'Ice cliffs and snowy peaks.', ['Flurry', 'Drift', 'Glacier', 'Icicle']),
  WorldEntry('volcanic', 'Volcanic Wasteland', 'Lava rivers under a smoky red sky.', ['Magma', 'Ash', 'Obsidian', 'Cinder']),
  WorldEntry('jungle', 'Lost Jungle Temple', 'Overgrown ruins hidden in the mist.', ['Vine', 'Fern', 'Relic', 'Canopy']),
  WorldEntry('cyber', 'Neon Cyber City', 'Skyscrapers glowing in the night.', ['Pixel', 'Combo', 'Glitch', 'Hologram']),
  WorldEntry('countryside', 'Sunny Countryside', 'Rolling hills, a red barn and a windmill.', ['Meadow', 'Harvest', 'Windmill', 'Barn']),
  WorldEntry('candy', 'Candy Wonderland', 'Pastel hills and peppermint trees.', ['Gumdrop', 'Sprinkle', 'Fudge', 'Lollipop']),
  WorldEntry('moonlit', 'Moonlit Forest', 'A huge moon over a quiet lake.', ['Moonbeam', 'Lantern', 'Hollow', 'Twilight']),
  WorldEntry('autumn', 'Autumn Valley', 'Golden leaves and a winding river.', ['Maple', 'Russet', 'Hearth', 'Rustle']),
  WorldEntry('ruins', 'Ancient Ruins', 'Colossal pillars and broken arches.', ['Pillar', 'Arch', 'Mosaic', 'Obelisk']),
  WorldEntry('tropical', 'Tropical Paradise', 'White sand and turquoise water.', ['Palm', 'Cove', 'Breeze', 'Sandbar']),
  WorldEntry('crystal', 'Crystal Caverns', 'Giant glowing gemstones underground.', ['Geode', 'Facet', 'Prism', 'Lumen']),
  WorldEntry('fairytale', 'Fairytale Kingdom', 'Castles, bridges and flowing waterfalls.', ['Turret', 'Drawbridge', 'Banner', 'Courtyard']),
  WorldEntry('treasure', 'Treasure Cavern', 'A chamber glittering with gold.', ['Ingot', 'Nugget', 'Hoard', 'Vault']),
  WorldEntry('sakura', 'Sakura Mountains', 'Cherry blossoms and torii gates.', ['Blossom', 'Torii', 'Petal', 'Zen']),
  WorldEntry('deepsea', 'Deep Sea Glow', 'Giant jellyfish in the dark blue.', ['Jelly', 'Glow', 'Abyss', 'Trench']),
  WorldEntry('skyislands', 'Floating Sky Islands', 'Islands drifting above the clouds.', ['Cloud', 'Zephyr', 'Gale', 'Aerie']),
];
