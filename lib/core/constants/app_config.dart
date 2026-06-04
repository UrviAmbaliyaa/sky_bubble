/// ─────────────────────────────────────────────────────────────────────────────
///  APP CONFIG — flip kTestingMode to true while developing / QA testing
/// ─────────────────────────────────────────────────────────────────────────────
///
///  When kTestingMode == true:
///    • Every level skin unlocks every 30 score points (instead of normal 50/150/…)
///    • Escaped bubbles do NOT remove a heart — test freely without game-over
///
///  Set to false before shipping to production.
/// ─────────────────────────────────────────────────────────────────────────────
const bool kTestingMode = true;
