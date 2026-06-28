import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Hosts tried in order; first success wins.
  static const _pingHosts = [
    '1.1.1.1',   // Cloudflare — fast, VPN-friendly
    '8.8.8.8',   // Google DNS
    '208.67.222.222', // OpenDNS
  ];

  Future<ConnectivityService> init() async {
    isOnline.value = await _hasRealInternet();

    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      if (!_anyInterface(results)) {
        isOnline.value = false;
      } else {
        isOnline.value = await _hasRealInternet();
      }
    });

    return this;
  }

  // DNS lookup against multiple hosts — works over VPN, mobile, WiFi, etc.
  Future<bool> _hasRealInternet() async {
    for (final host in _pingHosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  // True if any non-none interface is present (quick pre-check).
  bool _anyInterface(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
