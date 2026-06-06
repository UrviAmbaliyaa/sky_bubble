class BgAssets {
  static const _base = 'assets/backgrounds/';

  /// All 14 background images in loop order.
  static const List<String> all = [
    '${_base}bg_sky.png',
    '${_base}bg_dark_sky.png',
    '${_base}bg_gallaxy.png',
    '${_base}bg_garden.png',
    '${_base}bg_garden_gate.png',
    '${_base}bg_moonsoon.png',
    '${_base}bg_night.png',
    '${_base}bg_night_star.png',
    '${_base}beach_sky.png',
    '${_base}bg_morning.png',
    '${_base}bg_morning_view.png',
    '${_base}bg_morning_view_water.png',
    '${_base}bg_peacoc.png',
    '${_base}bs_morning.png',
  ];

  /// Returns the image for a given level, cycling back to index 0 after
  /// all 9 images have been used.
  /// Level 1 → all[0], Level 2 → all[1], … Level 9 → all[8],
  /// Level 10 → all[0] again, and so on.
  static String forLevel(int level) => all[(level - 1) % all.length];

  /// Home screen uses the first (daytime sky) image.
  static String get home => all[0];
}
