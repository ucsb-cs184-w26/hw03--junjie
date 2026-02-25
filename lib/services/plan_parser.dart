import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../models/floor_plan.dart';

FloorPlan parsePlanFromJson(String raw) {
  final dynamic decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object at the root.');
  }

  final Map<String, dynamic> planMap =
      (decoded['floorPlan'] as Map<String, dynamic>?) ?? decoded;
  final Map<String, dynamic> attrs =
      (planMap['@attributes'] as Map<String, dynamic>?) ?? const {};
  final double width = _readDouble(attrs['width'] ?? planMap['width']);
  final double height = _readDouble(attrs['height'] ?? planMap['height']);

  final dynamic roomsNode = planMap['rooms']?['room'] ?? planMap['room'];
  if (roomsNode == null) {
    throw const FormatException('No rooms found in JSON.');
  }
  final List<dynamic> roomsList = roomsNode is List ? roomsNode : [roomsNode];

  final List<FloorRoom> rooms = [];
  for (var i = 0; i < roomsList.length; i++) {
    final Map<String, dynamic> roomMap = roomsList[i] as Map<String, dynamic>;
    final Map<String, dynamic> roomAttrs =
        (roomMap['@attributes'] as Map<String, dynamic>?) ?? const {};
    final String id = (roomAttrs['id'] ?? roomMap['id'] ?? 'room_$i').toString();
    final String type =
        (roomAttrs['type'] ?? roomMap['type'] ?? 'room').toString();
    final String name = (roomMap['name'] ?? id).toString();

    final dynamic positionNode = roomMap['position'] ?? const {};
    final Map<String, dynamic> posAttrs;
    if (positionNode is Map<String, dynamic> &&
        positionNode['@attributes'] is Map<String, dynamic>) {
      posAttrs = positionNode['@attributes'] as Map<String, dynamic>;
    } else if (positionNode is Map<String, dynamic>) {
      posAttrs = positionNode;
    } else {
      posAttrs = const {};
    }

    final double x = _readDouble(posAttrs['x']);
    final double y = _readDouble(posAttrs['y']);
    final double w = _readDouble(posAttrs['width']);
    final double h = _readDouble(posAttrs['height']);

    final List<String> adjacent = _readStringList(roomMap['adjacentTo']);

    rooms.add(
      FloorRoom(
        id: id,
        type: type,
        name: name,
        rect: Rect.fromLTWH(x, y, w, h),
        adjacent: adjacent,
      ),
    );
  }

  return FloorPlan(width: width, height: height, rooms: rooms);
}

FloorPlan parsePlanFromXml(String raw) {
  final XmlDocument document = XmlDocument.parse(raw);
  final XmlElement planElement = document.findAllElements('floorPlan').first;
  final double width = _readDouble(planElement.getAttribute('width'));
  final double height = _readDouble(planElement.getAttribute('height'));

  final List<FloorRoom> rooms = [];
  for (final XmlElement room in planElement.findAllElements('room')) {
    final String id = room.getAttribute('id') ?? 'room_${rooms.length}';
    final String type = room.getAttribute('type') ?? 'room';
    final String name = room.getElement('name')?.innerText.trim() ?? id;
    final XmlElement? position = room.getElement('position');
    final double x = _readDouble(position?.getAttribute('x'));
    final double y = _readDouble(position?.getAttribute('y'));
    final double w = _readDouble(position?.getAttribute('width'));
    final double h = _readDouble(position?.getAttribute('height'));

    final List<String> adjacent = [];
    for (final XmlElement adj in room.findElements('adjacentTo')) {
      final String value = adj.innerText.trim();
      if (value.isNotEmpty) adjacent.add(value);
    }
    final String? adjAttr = room.getAttribute('adjacentTo');
    if (adjacent.isEmpty && adjAttr != null) {
      adjacent.addAll(
        adjAttr
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty),
      );
    }

    rooms.add(
      FloorRoom(
        id: id,
        type: type,
        name: name,
        rect: Rect.fromLTWH(x, y, w, h),
        adjacent: adjacent,
      ),
    );
  }

  double planWidth = width;
  double planHeight = height;
  if (planWidth <= 0 || planHeight <= 0) {
    double maxRight = 0;
    double maxBottom = 0;
    for (final room in rooms) {
      maxRight = math.max(maxRight, room.rect.right);
      maxBottom = math.max(maxBottom, room.rect.bottom);
    }
    planWidth = planWidth <= 0 ? maxRight : planWidth;
    planHeight = planHeight <= 0 ? maxBottom : planHeight;
  }

  return FloorPlan(width: planWidth, height: planHeight, rooms: rooms);
}

String fileExtension(String name) {
  final List<String> parts = name.split('.');
  if (parts.length < 2) return '';
  return parts.last.toLowerCase();
}

double _readDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<String> _readStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is Map && value['#text'] != null) {
    return [value['#text'].toString()];
  }
  return [value.toString()];
}
