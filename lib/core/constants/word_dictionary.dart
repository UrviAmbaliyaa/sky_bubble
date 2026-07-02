class WordEntry {
  final String word;
  final String emoji;
  const WordEntry(this.word, this.emoji);
}

class WordDictionary {
  // Level 1-10: 3-letter words (very easy)
  static const _easy = <WordEntry>[
    WordEntry('CAT', '🐱'), WordEntry('DOG', '🐶'), WordEntry('SUN', '☀️'),
    WordEntry('BEE', '🐝'), WordEntry('ANT', '🐜'), WordEntry('BUS', '🚌'),
    WordEntry('CUP', '☕'), WordEntry('EGG', '🥚'), WordEntry('FAN', '🌬️'),
    WordEntry('HAT', '🎩'), WordEntry('JAM', '🍓'), WordEntry('KEY', '🔑'),
    WordEntry('MAP', '🗺️'), WordEntry('NET', '🎣'), WordEntry('OWL', '🦉'),
    WordEntry('PIG', '🐷'), WordEntry('RAT', '🐀'), WordEntry('TUB', '🛁'),
    WordEntry('VAN', '🚐'), WordEntry('WEB', '🕷️'), WordEntry('BEG', '🙏'),
    WordEntry('COW', '🐄'), WordEntry('FOX', '🦊'), WordEntry('HEN', '🐓'),
    WordEntry('JAR', '🫙'), WordEntry('LOG', '🪵'), WordEntry('MUD', '🟫'),
    WordEntry('NUT', '🥜'), WordEntry('POT', '🪴'), WordEntry('RIB', '🍖'),
  ];

  // Level 11-30: 4-letter words
  static const _medium = <WordEntry>[
    WordEntry('BALL', '⚽'), WordEntry('BEAR', '🐻'), WordEntry('BIRD', '🐦'),
    WordEntry('BOAT', '⛵'), WordEntry('BOOK', '📚'), WordEntry('CAKE', '🎂'),
    WordEntry('CRAB', '🦀'), WordEntry('DEER', '🦌'), WordEntry('DUCK', '🦆'),
    WordEntry('FISH', '🐟'), WordEntry('FLAG', '🚩'), WordEntry('FROG', '🐸'),
    WordEntry('GOAT', '🐐'), WordEntry('KITE', '🪁'), WordEntry('LAMP', '💡'),
    WordEntry('LEAF', '🍃'), WordEntry('LION', '🦁'), WordEntry('MILK', '🥛'),
    WordEntry('MOON', '🌙'), WordEntry('PEAR', '🍐'), WordEntry('RAIN', '🌧️'),
    WordEntry('RING', '💍'), WordEntry('ROSE', '🌹'), WordEntry('SHIP', '🚢'),
    WordEntry('STAR', '⭐'), WordEntry('SWAN', '🦢'), WordEntry('TREE', '🌲'),
    WordEntry('WOLF', '🐺'), WordEntry('CORN', '🌽'), WordEntry('NEST', '🪺'),
    WordEntry('SEED', '🌱'), WordEntry('SNOB', '🐛'), WordEntry('TOAD', '🐸'),
    WordEntry('BELL', '🔔'), WordEntry('CAPE', '🦸'), WordEntry('CAVE', '🏔️'),
    WordEntry('CLAY', '🏺'), WordEntry('CLAW', '🦞'), WordEntry('COIN', '🪙'),
    WordEntry('COLT', '🐴'), WordEntry('COOP', '🐔'), WordEntry('DIME', '💰'),
    WordEntry('DOVE', '🕊️'), WordEntry('DRUM', '🥁'), WordEntry('DUSK', '🌆'),
    WordEntry('FOAM', '🫧'), WordEntry('FORK', '🍴'), WordEntry('FAWN', '🦌'),
    WordEntry('GEMS', '💎'), WordEntry('GLOW', '✨'),
  ];

  // Level 31-60: 5-letter words
  static const _hard = <WordEntry>[
    WordEntry('APPLE', '🍎'), WordEntry('BEACH', '🏖️'), WordEntry('CAMEL', '🐪'),
    WordEntry('CANDY', '🍬'), WordEntry('CHAIR', '🪑'), WordEntry('CHICK', '🐥'),
    WordEntry('CLOCK', '⏰'), WordEntry('CLOUD', '☁️'), WordEntry('EAGLE', '🦅'),
    WordEntry('EARTH', '🌍'), WordEntry('FLAME', '🔥'), WordEntry('GLOBE', '🌐'),
    WordEntry('GRAPE', '🍇'), WordEntry('GRASS', '🌿'), WordEntry('HORSE', '🐴'),
    WordEntry('HOUSE', '🏠'), WordEntry('JUICE', '🧃'), WordEntry('KOALA', '🐨'),
    WordEntry('LEMON', '🍋'), WordEntry('LLAMA', '🦙'), WordEntry('LOTUS', '🪷'),
    WordEntry('MAPLE', '🍁'), WordEntry('MELON', '🍈'), WordEntry('MOUSE', '🐭'),
    WordEntry('OCEAN', '🌊'), WordEntry('OLIVE', '🫒'), WordEntry('OTTER', '🦦'),
    WordEntry('PANDA', '🐼'), WordEntry('PASTA', '🍝'), WordEntry('PEACH', '🍑'),
    WordEntry('PIANO', '🎹'), WordEntry('PIZZA', '🍕'), WordEntry('PLANE', '✈️'),
    WordEntry('PLANT', '🌱'), WordEntry('QUEEN', '👑'), WordEntry('RIVER', '🏞️'),
    WordEntry('ROBOT', '🤖'), WordEntry('SHARK', '🦈'), WordEntry('SHEEP', '🐑'),
    WordEntry('SHELL', '🐚'), WordEntry('SNAKE', '🐍'), WordEntry('SNAIL', '🐌'),
    WordEntry('STORM', '⛈️'), WordEntry('TIGER', '🐯'), WordEntry('TOAST', '🍞'),
    WordEntry('TORCH', '🔦'), WordEntry('TRAIN', '🚂'), WordEntry('TULIP', '🌷'),
    WordEntry('WATER', '💧'), WordEntry('WHALE', '🐋'), WordEntry('WHEAT', '🌾'),
    WordEntry('WITCH', '🧙'), WordEntry('YACHT', '⛵'), WordEntry('ZEBRA', '🦓'),
    WordEntry('ACORN', '🌰'), WordEntry('ANGEL', '👼'), WordEntry('ARROW', '➡️'),
    WordEntry('BISON', '🦬'), WordEntry('BLAZE', '🔥'), WordEntry('BLOOM', '🌸'),
  ];

  // Level 61+: 6-letter words
  static const _expert = <WordEntry>[
    WordEntry('BANANA', '🍌'), WordEntry('BEAVER', '🦫'), WordEntry('BEETLE', '🐞'),
    WordEntry('BOTTLE', '🍶'), WordEntry('BRIDGE', '🌉'), WordEntry('BUTTER', '🧈'),
    WordEntry('CACTUS', '🌵'), WordEntry('CAMERA', '📷'), WordEntry('CANDLE', '🕯️'),
    WordEntry('CASTLE', '🏰'), WordEntry('CHERRY', '🍒'), WordEntry('COFFEE', '☕'),
    WordEntry('CRAYON', '🖍️'), WordEntry('DANCER', '💃'), WordEntry('DESERT', '🏜️'),
    WordEntry('DONKEY', '🫏'), WordEntry('DRAGON', '🐉'), WordEntry('FALCON', '🦅'),
    WordEntry('FINGER', '👆'), WordEntry('FLOWER', '🌸'), WordEntry('FOREST', '🌳'),
    WordEntry('GARDEN', '🌷'), WordEntry('GARLIC', '🧄'), WordEntry('GOBLIN', '👺'),
    WordEntry('GUITAR', '🎸'), WordEntry('HARBOR', '⚓'), WordEntry('HELMET', '⛑️'),
    WordEntry('ISLAND', '🏝️'), WordEntry('JAGUAR', '🐆'), WordEntry('JUNGLE', '🌴'),
    WordEntry('KITTEN', '🐱'), WordEntry('KNIGHT', '♞'), WordEntry('LAPTOP', '💻'),
    WordEntry('LIZARD', '🦎'), WordEntry('MARBLE', '🪨'), WordEntry('MIRROR', '🪞'),
    WordEntry('MONKEY', '🐒'), WordEntry('MUFFIN', '🧁'), WordEntry('NEEDLE', '🧵'),
    WordEntry('ORANGE', '🍊'), WordEntry('ORCHID', '🌺'), WordEntry('PARROT', '🦜'),
    WordEntry('PENCIL', '✏️'), WordEntry('PEPPER', '🌶️'), WordEntry('PIGEON', '🕊️'),
    WordEntry('POTATO', '🥔'), WordEntry('PYTHON', '🐍'), WordEntry('RABBIT', '🐰'),
    WordEntry('RACOON', '🦝'), WordEntry('ROCKET', '🚀'), WordEntry('SALMON', '🐟'),
    WordEntry('SHIELD', '🛡️'), WordEntry('SILVER', '🥈'), WordEntry('SPIDER', '🕷️'),
    WordEntry('SPLASH', '💦'), WordEntry('SPRING', '🌱'), WordEntry('SUMMER', '☀️'),
    WordEntry('SUNSET', '🌅'), WordEntry('TURTLE', '🐢'), WordEntry('WALNUT', '🥜'),
    WordEntry('WALRUS', '🦭'), WordEntry('WINTER', '❄️'), WordEntry('YELLOW', '💛'),
  ];

  /// Public pool for the given level — used by LearningController for shuffle queue.
  static List<WordEntry> poolForLevel(int level) {
    if (level <= 10)  return List.unmodifiable(_easy);
    if (level <= 30)  return List.unmodifiable(_medium);
    if (level <= 60)  return List.unmodifiable(_hard);
    return List.unmodifiable(_expert);
  }
}
