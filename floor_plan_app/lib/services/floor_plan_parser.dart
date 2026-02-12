import 'package:xml/xml.dart';
import '../models/floor_plan.dart';

class FloorPlanParser {
  static FloorPlan parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final floorPlanElement = document.findElements('floorPlan').first;

    final planWidth = double.parse(floorPlanElement.getAttribute('width')!);
    final planHeight = double.parse(floorPlanElement.getAttribute('height')!);

    final rooms = <Room>[];
    final roomElements =
        floorPlanElement.findElements('rooms').first.findElements('room');

    for (final roomElement in roomElements) {
      final positionElement = roomElement.findElements('position').first;
      final adjacentTo = roomElement
          .findElements('adjacentTo')
          .map((e) => e.innerText)
          .toList();

      rooms.add(Room(
        id: roomElement.getAttribute('id')!,
        type: roomElement.getAttribute('type')!,
        name: roomElement.findElements('name').first.innerText,
        x: double.parse(positionElement.getAttribute('x')!),
        y: double.parse(positionElement.getAttribute('y')!),
        width: double.parse(positionElement.getAttribute('width')!),
        height: double.parse(positionElement.getAttribute('height')!),
        adjacentTo: adjacentTo,
      ));
    }

    return FloorPlan(width: planWidth, height: planHeight, rooms: rooms);
  }
}
