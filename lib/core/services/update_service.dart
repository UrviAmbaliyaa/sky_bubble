import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService extends GetxService {
  // ─────────────────────────────────────────────────────────────────────────
  //  DEBUG TESTING FLAG
  //  Set to true to force the update popup in debug builds.
  //  Switch back to false (or remove) before releasing to production.
  // ─────────────────────────────────────────────────────────────────────────
  static const bool _debugForceUpdate = false;

  final RxBool updateRequired = false.obs;

  String get storeUrl => Platform.isIOS
      ? 'https://apps.apple.com/app/id$_appleAppId'
      : 'https://play.google.com/store/apps/details?id=$_androidPackage';

  static const _androidPackage = 'com.bubble.skybubbleburst';
  static const _appleAppId    = '';

  Future<UpdateService> init() async {
    // In debug mode, honour the force flag immediately — no network call needed.
    if (kDebugMode && _debugForceUpdate) {
      updateRequired.value = true;
      return this;
    }

    try {
      final info    = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final latest = Platform.isIOS
          ? await _fetchIosVersion()
          : await _fetchAndroidVersion();

      if (latest != null && _isOutdated(current, latest)) {
        updateRequired.value = true;
      }
    } catch (_) {
      // Never block the user if the check itself fails.
    }
    return this;
  }

  // ── iOS: official iTunes lookup API ──────────────────────────────────────

  Future<List<int>?> _fetchIosVersion() async {
    if (_appleAppId.isEmpty) return null;
    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/lookup?bundleId=$_androidPackage');
      final client = HttpClient();
      final req    = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Mozilla/5.0');
      final res  = await req.close().timeout(const Duration(seconds: 8));
      final body = await res.transform(utf8.decoder).join();
      client.close();
      final json    = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final version = results.first['version'] as String?;
      return version != null ? _parseVersion(version) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Android: Play Store HTML scrape ──────────────────────────────────────

  Future<List<int>?> _fetchAndroidVersion() async {
    try {
      final uri = Uri.parse(
          'https://play.google.com/store/apps/details?id=$_androidPackage&hl=en');
      final client = HttpClient();
      final req    = await client.getUrl(uri);
      req.headers.set('User-Agent',
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36');
      final res  = await req.close().timeout(const Duration(seconds: 10));
      final body = await res.transform(utf8.decoder).join();
      client.close();

      // Play Store embeds version as: [[["X.Y.Z"]]] in a JS data block.
      final regex = RegExp(r'\[\[\["(\d+\.\d+(?:\.\d+)?)"\]\]');
      final match = regex.firstMatch(body);
      final version = match?.group(1);
      return version != null ? _parseVersion(version) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<int> _parseVersion(String v) => v
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  bool _isOutdated(List<int> current, List<int> latest) {
    final len = latest.length > current.length ? latest.length : current.length;
    for (var i = 0; i < len; i++) {
      final c = i < current.length ? current[i] : 0;
      final l = i < latest.length ? latest[i] : 0;
      if (l > c) return true;
      if (c > l) return false;
    }
    return false;
  }
}
