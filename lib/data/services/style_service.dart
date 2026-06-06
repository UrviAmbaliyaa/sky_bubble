import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/bubble_styles.dart';

/// Persists the user's chosen bubble style across sessions.
class StyleService extends GetxService {
  static const _key = 'bubble_style';
  late final GetStorage _box;

  final Rx<BubbleStyle> selectedStyle = BubbleStyle.classic.obs;

  Future<StyleService> init() async {
    _box = GetStorage();
    final saved = _box.read<String>(_key);
    if (saved != null) {
      selectedStyle.value = BubbleStyleInfo.fromKey(saved);
    }
    return this;
  }

  void setStyle(BubbleStyle style) {
    selectedStyle.value = style;
    _box.write(_key, style.key);
  }
}
