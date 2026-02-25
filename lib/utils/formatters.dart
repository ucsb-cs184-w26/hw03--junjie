import 'dart:math' as math;

String formatMeters(double value) {
  final String fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

double radiansToDegrees(double radians) {
  final double deg = radians * (180 / math.pi);
  final double normalized = deg % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

double degreesToRadians(double degrees) {
  return degrees * (math.pi / 180);
}
