import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Rotating pool of AudioPlayer instances for zero-latency, guaranteed pops.
///
/// Root cause of dropped sounds: calling player.stop() before player.play()
/// without awaiting the Future causes a race condition — the async stop can
/// cancel the already-queued play().  Fix: never stop before playing; rotate
/// to the next player and call play() directly.  ReleaseMode.stop means each
/// player auto-idles after its clip finishes, so the slot is clean on reuse.
class SoundService extends GetxService {
  // 10 slots → even rapid tapping never hits the same player twice in a row.
  static const _popPoolSize = 10;
  final List<AudioPlayer> _popPool = [];
  int _popIdx = 0;

  final AudioPlayer _spawnPlayer = AudioPlayer();
  DateTime _lastSpawnAt = DateTime(2000);

  final RxBool isMuted = false.obs;

  void toggleMute() => isMuted.value = !isMuted.value;

  Future<SoundService> init() async {
    for (int i = 0; i < _popPoolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _popPool.add(p);
    }
    await _spawnPlayer.setReleaseMode(ReleaseMode.stop);

    // Pre-cache both assets so the very first playback has no I/O delay.
    await AudioCache.instance.loadAll([
      'voice/bubble_pop.mp3',
      'voice/bubble.mp3',
    ]);
    return this;
  }

  /// Guaranteed pop sound on every bubble tap.
  /// We rotate to the NEXT player and call play() directly — no stop() call,
  /// which avoids the async race that previously caused missed sounds.
  void playPop() {
    if (isMuted.value) return;
    final player = _popPool[_popIdx % _popPoolSize];
    _popIdx++;
    player.play(AssetSource('voice/bubble_pop.mp3'));
  }

  /// Spawn sound throttled to at most once per 800 ms to avoid audio spam.
  void playBubbleSpawn() {
    if (isMuted.value) return;
    final now = DateTime.now();
    if (now.difference(_lastSpawnAt).inMilliseconds < 800) return;
    _lastSpawnAt = now;
    // stop() is safe here because we await nothing — spawn is low-frequency.
    _spawnPlayer.stop().then((_) =>
        _spawnPlayer.play(AssetSource('voice/bubble.mp3')));
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
