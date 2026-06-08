import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  COIN DISPLAY  — reusable coin image + amount widget
//
//  Usage:
//    CoinDisplay(amount: 400)                // default size
//    CoinDisplay(amount: 50, imageSize: 14)  // small (for badges)
//    CoinDisplay(amount: 5,  imageSize: 22)  // large (for reward cards)
//    CoinDisplay.iconOnly(size: 18)          // just the coin image, no text
// ═══════════════════════════════════════════════════════════════════════════════

class CoinDisplay extends StatelessWidget {
  final int?   amount;       // null → icon-only mode
  final double imageSize;    // width/height of the coin image (logical px)
  final double? fontSize;    // text size; defaults to imageSize * 0.85
  final Color  textColor;
  final FontWeight fontWeight;
  final double gap;          // space between image and text

  const CoinDisplay({
    super.key,
    required this.amount,
    this.imageSize  = 18,
    this.fontSize,
    this.textColor  = Colors.white,
    this.fontWeight = FontWeight.w900,
    this.gap        = 4,
  });

  /// Shows only the coin image — no number.
  const CoinDisplay.iconOnly({
    super.key,
    this.imageSize = 18,
  })  : amount     = null,
        fontSize   = null,
        textColor  = Colors.white,
        fontWeight = FontWeight.w900,
        gap        = 0;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? imageSize * 0.85;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/coin.png',
          width:  imageSize,
          height: imageSize,
          fit: BoxFit.contain,
        ),
        if (amount != null) ...[
          SizedBox(width: gap),
          Text(
            '$amount',
            style: TextStyle(
              fontSize:   effectiveFontSize,
              fontWeight: fontWeight,
              color:      textColor,
              height:     1.0,
            ),
          ),
        ],
      ],
    );
  }
}
