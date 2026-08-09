import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_pumping/data/models/bubble_model.dart';

void main() {
  group('BubbleModel', () {
    test('default properties and state getters', () {
      final bubble = BubbleModel(
        id: 'bubble_1',
        color: Colors.blue,
        x: 100.0,
        y: 200.0,
        radius: 30.0,
        speed: 2.0,
        driftAmplitude: 10.0,
        driftFrequency: 0.5,
      );

      expect(bubble.id, equals('bubble_1'));
      expect(bubble.isPopped, isFalse);
      expect(bubble.isBursting, isFalse);
      expect(bubble.isActive, isTrue);
      expect(bubble.canPop, isTrue);
      expect(bubble.pointValue, equals(1));

      bubble.isPopped = true;
      expect(bubble.canPop, isFalse);
      expect(bubble.isActive, isFalse);

      bubble.isBursting = true;
      expect(bubble.isActive, isTrue);
    });
  });
}
