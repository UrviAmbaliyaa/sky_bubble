import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ad_watch_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD WATCH SCREEN  — intentionally minimal
//
//  Pure black full-screen background with a single centered loading spinner.
//  No text, no progress indicators, no decorations.
//
//  The ads themselves (AdMob interstitials) cover the full screen and include
//  AdMob's own built-in countdown / close-button timer.  There is nothing
//  extra to show between ads — the spinner is only briefly visible while the
//  very first ad is loading at launch.
// ═══════════════════════════════════════════════════════════════════════════════

class AdWatchScreen extends StatelessWidget {
  const AdWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdWatchController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ctrl.cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: Colors.white.withOpacity(0.70),
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ),
    );
  }
}
