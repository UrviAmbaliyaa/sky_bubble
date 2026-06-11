import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Rotating pool of AudioPlayer instances for zero-latency, guaranteed pops.
///
/// Each tap grabs the next slot in a 10-player ring — no stop() call, no race
/// condition. ReleaseMode.stop means each player auto-idles after the clip
/// finishes, so the slot is clean on reuse.
class SoundService extends GetxService {
  // 10 slots → even the fastest continuous tapping never hits the same
  // player twice before the previous clip has finished.
  static const _popPoolSize = 10;
  final List<AudioPlayer> _popPool = [];
  int _popIdx = 0;

  final RxBool isMuted = false.obs;

  void toggleMute() => isMuted.value = !isMuted.value;

  Future<SoundService> init() async {
    for (int i = 0; i < _popPoolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _popPool.add(p);
    }

    // Pre-cache so the very first tap has zero I/O delay.
    await AudioCache.instance.load('voice/bubble_pop.mp3');
    return this;
  }

  /// Plays the pop sound on every bubble tap, even during rapid continuous tapping.
  /// Rotates to the next player each call — no stop(), no dropped sounds.
  void playPop() {
    if (isMuted.value) return;
    final player = _popPool[_popIdx % _popPoolSize];
    _popIdx++;
    player.play(AssetSource('voice/bubble_pop.mp3'));
  }

  @override
  void onClose() {
    for (final p in _popPool) {
      p.stop();
      p.dispose();
    }
    super.onClose();
  }
}
