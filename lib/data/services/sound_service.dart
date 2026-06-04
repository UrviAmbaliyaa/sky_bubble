import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Uses a rotating pool of AudioPlayer instances so old players are always
/// stopped and reused — no leaked / overloaded instances.
class SoundService extends GetxService {
  static const _popPoolSize = 6;
  final List<AudioPlayer> _popPool = [];
  int _popIdx = 0;

  final AudioPlayer _spawnPlayer = AudioPlayer();
  DateTime _lastSpawnAt = DateTime(2000);

  Future<SoundService> init() async {
    // Pre-create pop pool — each player is stopped before reuse
    for (int i = 0; i < _popPoolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _popPool.add(p);
    }
    await _spawnPlayer.setReleaseMode(ReleaseMode.stop);

    // Pre-cache both clips so first playback has zero lag
    await AudioCache.instance.loadAll([
      'voice/bubble_pop.mp3',
      'voice/bubble.mp3',
    ]);
    return this;
  }

  /// Played every time the user pops a bubble.
  /// Rotates through a pool — guaranteed the previous pop is stopped first.
  void playPop() {
    final player = _popPool[_popIdx % _popPoolSize];
    _popIdx++;
    player.stop();
    player.play(AssetSource('voice/bubble_pop.mp3'));
  }

  /// Played when a new bubble spawns — throttled to once per 900 ms.
  void playBubbleSpawn() {
    final now = DateTime.now();
    if (now.difference(_lastSpawnAt).inMilliseconds < 900) return;
    _lastSpawnAt = now;
    _spawnPlayer.stop();
    _spawnPlayer.play(AssetSource('voice/bubble.mp3'));
  }

  @override
  void onClose() {
    for (final p in _popPool) {
      p.stop();
      p.dispose();
    }
    _spawnPlayer.stop();
    _spawnPlayer.dispose();
    super.onClose();
  }
}
