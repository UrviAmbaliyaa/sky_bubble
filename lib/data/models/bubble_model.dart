import 'package:flutter/material.dart';

class BubbleModel {
  final String id;
  final Color color;
  double x;
  double y;
  final double radius;
  final double speed;
  double driftAngle;
  final double driftAmplitude;
  final double driftFrequency;
  bool isPopped;
  bool isBursting;
  double burstProgress;
  /// Points awarded when this bubble is popped (1–5 for normal, 100 for special).
  final int pointValue;
  /// True for the rare golden home-style bubble worth 100 pts.
  final bool isSpecial;
  /// True for the once-per-level gift bubble — triggers ad → gift flow on pop.
  final bool isGift;
  /// True for a locked-style teaser bubble — shows a lock icon, 0 pts on pop.
  final bool isLocked;

  BubbleModel({
    required this.id,
    required this.color,
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    this.driftAngle = 0.0,
    required this.driftAmplitude,
    required this.driftFrequency,
    this.isPopped = false,
    this.isBursting = false,
    this.burstProgress = 0.0,
    this.pointValue = 1,
    this.isSpecial = false,
    this.isGift = false,
    this.isLocked = false,
  });

  bool get isActive => !isPopped || isBursting;
  bool get canPop => !isPopped && !isBursting;
}
