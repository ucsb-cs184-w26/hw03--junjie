import 'package:flutter/material.dart';

class FloorPlan {
  const FloorPlan({
    required this.width,
    required this.height,
    required this.rooms,
  });

  final double width;
  final double height;
  final List<FloorRoom> rooms;
}

class FloorRoom {
  const FloorRoom({
    required this.id,
    required this.type,
    required this.name,
    required this.rect,
    required this.adjacent,
  });

  final String id;
  final String type;
  final String name;
  final Rect rect;
  final List<String> adjacent;
}
