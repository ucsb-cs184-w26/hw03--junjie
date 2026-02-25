import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/floor_plan.dart';

class PlanTransform {
  const PlanTransform({
    required this.scale,
    required this.offset,
  });

  final double scale;
  final Offset offset;

  Rect toCanvas(Rect rect) {
    return Rect.fromLTWH(
      offset.dx + rect.left * scale,
      offset.dy + rect.top * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }

  Offset fromCanvas(Offset point) {
    return Offset(
      (point.dx - offset.dx) / scale,
      (point.dy - offset.dy) / scale,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanTransform &&
        other.scale == scale &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(scale, offset);
}

PlanTransform computePlanTransform(Size size, FloorPlan plan) {
  final double pad = size.shortestSide * 0.06;
  final double safeWidth = plan.width <= 0 ? 1 : plan.width;
  final double safeHeight = plan.height <= 0 ? 1 : plan.height;
  final double scale = math.min(
    (size.width - pad * 2) / safeWidth,
    (size.height - pad * 2) / safeHeight,
  );
  final double offsetX = (size.width - safeWidth * scale) / 2;
  final double offsetY = (size.height - safeHeight * scale) / 2;
  return PlanTransform(scale: scale, offset: Offset(offsetX, offsetY));
}
