import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/floor_plan.dart';

List<Rect> computeDoorways(FloorPlan plan) {
  final Map<String, FloorRoom> byId = {
    for (final room in plan.rooms) room.id: room,
  };
  final Set<String> visited = {};
  final List<Rect> doors = [];
  final double base = math.min(plan.width, plan.height);

  for (final room in plan.rooms) {
    for (final adjacent in room.adjacent) {
      final FloorRoom? other = byId[adjacent];
      if (other == null) continue;

      final String key = room.id.compareTo(other.id) < 0
          ? '${room.id}|${other.id}'
          : '${other.id}|${room.id}';
      if (!visited.add(key)) continue;

      final Rect? door = _sharedDoorwayRect(room.rect, other.rect, base);
      if (door != null) {
        doors.add(door);
      }
    }
  }

  return doors;
}

Rect? _sharedDoorwayRect(Rect a, Rect b, double base) {
  const double epsilon = 1e-6;
  final double doorThickness = base * 0.02;
  final double maxDoorLength = base * 0.08;

  if ((a.right - b.left).abs() < epsilon || (b.right - a.left).abs() < epsilon) {
    final double edgeX = (a.right - b.left).abs() < epsilon ? a.right : b.right;
    final double overlapTop = math.max(a.top, b.top);
    final double overlapBottom = math.min(a.bottom, b.bottom);
    final double overlap = overlapBottom - overlapTop;
    if (overlap <= 0) return null;
    final double doorLength = math.min(maxDoorLength, overlap * 0.6);
    final double centerY = (overlapTop + overlapBottom) / 2;
    return Rect.fromCenter(
      center: Offset(edgeX, centerY),
      width: doorThickness,
      height: doorLength,
    );
  }

  if ((a.bottom - b.top).abs() < epsilon || (b.bottom - a.top).abs() < epsilon) {
    final double edgeY = (a.bottom - b.top).abs() < epsilon ? a.bottom : b.bottom;
    final double overlapLeft = math.max(a.left, b.left);
    final double overlapRight = math.min(a.right, b.right);
    final double overlap = overlapRight - overlapLeft;
    if (overlap <= 0) return null;
    final double doorLength = math.min(maxDoorLength, overlap * 0.6);
    final double centerX = (overlapLeft + overlapRight) / 2;
    return Rect.fromCenter(
      center: Offset(centerX, edgeY),
      width: doorLength,
      height: doorThickness,
    );
  }

  return null;
}
