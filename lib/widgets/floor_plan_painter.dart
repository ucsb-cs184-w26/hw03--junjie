import 'package:flutter/material.dart';

import '../models/floor_plan.dart';
import '../utils/app_constants.dart';
import '../utils/doorways.dart';
import '../utils/geometry.dart';

class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter(this.plan, this.transform);

  final FloorPlan plan;
  final PlanTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    Rect toCanvas(Rect rect) => transform.toCanvas(rect);

    final Paint roomPaint = Paint()..style = PaintingStyle.fill;
    final Paint wallPaint = Paint()
      ..color = kWallColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final Paint doorPaint = Paint()
      ..color = kDoorColor
      ..style = PaintingStyle.fill;

    for (final room in plan.rooms) {
      roomPaint.color = _roomColor(room.type);
      canvas.drawRect(toCanvas(room.rect), roomPaint);
    }

    for (final room in plan.rooms) {
      canvas.drawRect(toCanvas(room.rect), wallPaint);
    }

    final Rect planBounds = toCanvas(Rect.fromLTWH(0, 0, plan.width, plan.height));
    canvas.drawRect(planBounds, wallPaint);

    for (final Rect door in computeDoorways(plan)) {
      canvas.drawRect(toCanvas(door), doorPaint);
    }

    final double fontSize = (12 * transform.scale).clamp(10, 18).toDouble();
    for (final room in plan.rooms) {
      _drawLabel(canvas, toCanvas(room.rect), room.name, fontSize);
    }
  }

  Color _roomColor(String type) {
    switch (type.toLowerCase()) {
      case 'living':
        return const Color(0xFFF8EFD3);
      case 'kitchen':
        return const Color(0xFFDCECD8);
      case 'bedroom':
        return const Color(0xFFD9E8F7);
      case 'bathroom':
        return const Color(0xFFD8E4D3);
      default:
        return const Color(0xFFF1EEE6);
    }
  }

  void _drawLabel(Canvas canvas, Rect area, String text, double fontSize) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: area.width - 8);

    final Offset offset = Offset(
      area.center.dx - painter.width / 2,
      area.center.dy - painter.height / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.plan != plan || oldDelegate.transform != transform;
  }
}
