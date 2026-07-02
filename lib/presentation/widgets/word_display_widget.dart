import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

/// Floating word-display panel for the learning screen.
/// Readable on any background: dark pill with subtle border.
/// Unrevealed letters are dim white; revealed letters pop to green.
class WordDisplayWidget extends StatefulWidget {
  final String word;
  final Set<int> revealedIndices;

  const WordDisplayWidget({
    super.key,
    required this.word,
    required this.revealedIndices,
  });

  @override
  State<WordDisplayWidget> createState() => _WordDisplayWidgetState();
}

class _WordDisplayWidgetState extends State<WordDisplayWidget>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls  = [];
  final List<Animation<double>>   _scales = [];
  Set<int> _prevRevealed = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final c in _ctrls) c.dispose();
    _ctrls.clear();
    _scales.clear();
    for (int i = 0; i < widget.word.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      _ctrls.add(ctrl);
      _scales.add(
        Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
        ),
      );
      if (widget.revealedIndices.contains(i)) ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(WordDisplayWidget old) {
    super.didUpdateWidget(old);
    if (old.word != widget.word) {
      _initControllers();
      _prevRevealed = {};
      return;
    }
    for (int i = 0; i < widget.word.length; i++) {
      if (widget.revealedIndices.contains(i) && !_prevRevealed.contains(i)) {
        if (i < _ctrls.length) _ctrls[i].forward(from: 0.0);
      }
    }
    _prevRevealed = Set.from(widget.revealedIndices);
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revealed = widget.revealedIndices.length;
    final total    = widget.word.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label + progress ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPELL THE WORD',
                style: TextStyle(
                  fontSize:   7.5.sp,
                  fontWeight: FontWeight.w700,
                  color:      Colors.white.withOpacity(0.70),
                  letterSpacing: 1.8,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: revealed == total
                      ? const Color(0xFF43E97B)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$revealed/$total',
                  style: TextStyle(
                    fontSize:   7.5.sp,
                    fontWeight: FontWeight.w800,
                    color:      Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.0.h),

          // ── Word letters ─────────────────────────────────────────────────────
          Wrap(
            alignment:  WrapAlignment.center,
            spacing:    1.2.w,
            runSpacing: 0.6.h,
            children: List.generate(widget.word.length, (i) {
              final isRevealed = widget.revealedIndices.contains(i);
              final anim       = i < _scales.length ? _scales[i] : null;

              final Widget letter = _LetterTile(
                char:       widget.word[i],
                isRevealed: isRevealed,
              );

              if (!isRevealed || anim == null) return letter;
              return AnimatedBuilder(
                animation: anim,
                builder:   (_, child) => Transform.scale(scale: anim.value, child: child),
                child:     letter,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Single letter tile ───────────────────────────────────────────────────────

class _LetterTile extends StatelessWidget {
  final String char;
  final bool   isRevealed;
  const _LetterTile({required this.char, required this.isRevealed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: isRevealed
            ? const Color(0xFF43E97B)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRevealed
              ? const Color(0xFF2ECC71)
              : Colors.white.withOpacity(0.60),
          width: 1.8,
        ),
        boxShadow: isRevealed
            ? [
                BoxShadow(
                  color:       const Color(0xFF43E97B).withOpacity(0.55),
                  blurRadius:  12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize:   14.sp,
            fontWeight: FontWeight.w900,
            color: isRevealed ? Colors.white : Colors.white,
            height: 1.0,
            shadows: isRevealed
                ? const [Shadow(color: Colors.black26, blurRadius: 4)]
                : null,
          ),
        ),
      ),
    );
  }
}
