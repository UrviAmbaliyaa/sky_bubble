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
  });

  bool get isActive => !isPopped || isBursting;
  bool get canPop => !isPopped && !isBursting;
}
