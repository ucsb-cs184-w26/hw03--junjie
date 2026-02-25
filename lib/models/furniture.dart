import 'package:flutter/material.dart';

class FurnitureSpec {
  const FurnitureSpec({
    required this.name,
    required this.sizeLabel,
    required this.width,
    required this.height,
    required this.tags,
  });

  final String name;
  final String sizeLabel;
  final double width;
  final double height;
  final List<String> tags;
}

class PlacedFurniture {
  const PlacedFurniture({
    required this.id,
    required this.spec,
    required this.position,
    required this.rotation,
  });

  final String id;
  final FurnitureSpec spec;
  final Offset position;
  final double rotation;

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, spec.width, spec.height);

  PlacedFurniture copyWith({Offset? position, double? rotation}) {
    return PlacedFurniture(
      id: id,
      spec: spec,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
    );
  }
}

const List<FurnitureSpec> kFurnitureCatalog = [
  FurnitureSpec(
    name: '3-Seat Sofa',
    sizeLabel: '2.2m x 0.9m',
    width: 2.2,
    height: 0.9,
    tags: ['Living'],
  ),
  FurnitureSpec(
    name: 'Armchair',
    sizeLabel: '0.9m x 0.9m',
    width: 0.9,
    height: 0.9,
    tags: ['Living'],
  ),
  FurnitureSpec(
    name: 'Coffee Table',
    sizeLabel: '1.2m x 0.6m',
    width: 1.2,
    height: 0.6,
    tags: ['Living'],
  ),
  FurnitureSpec(
    name: 'Queen Bed',
    sizeLabel: '2.03m x 1.52m',
    width: 2.03,
    height: 1.52,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Twin Bed',
    sizeLabel: '1.9m x 0.99m',
    width: 1.9,
    height: 0.99,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Bunk Bed',
    sizeLabel: '2.0m x 0.95m',
    width: 2.0,
    height: 0.95,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Wardrobe',
    sizeLabel: '1.2m x 0.6m',
    width: 1.2,
    height: 0.6,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Dresser',
    sizeLabel: '1.0m x 0.5m',
    width: 1.0,
    height: 0.5,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Dining Table',
    sizeLabel: '1.6m x 0.9m',
    width: 1.6,
    height: 0.9,
    tags: ['Dining', 'Kitchen'],
  ),
  FurnitureSpec(
    name: 'Nightstand',
    sizeLabel: '0.5m x 0.45m',
    width: 0.5,
    height: 0.45,
    tags: ['Bedroom'],
  ),
  FurnitureSpec(
    name: 'Dining Chair',
    sizeLabel: '0.45m x 0.45m',
    width: 0.45,
    height: 0.45,
    tags: ['Dining', 'Kitchen'],
  ),
  FurnitureSpec(
    name: 'Desk',
    sizeLabel: '1.2m x 0.6m',
    width: 1.2,
    height: 0.6,
    tags: ['Office', 'Bedroom'],
  ),
  FurnitureSpec(
    name: 'Office Chair',
    sizeLabel: '0.6m x 0.6m',
    width: 0.6,
    height: 0.6,
    tags: ['Office'],
  ),
  FurnitureSpec(
    name: 'Bookshelf',
    sizeLabel: '0.9m x 0.3m',
    width: 0.9,
    height: 0.3,
    tags: ['Living', 'Office', 'Bedroom'],
  ),
  FurnitureSpec(
    name: 'TV Stand',
    sizeLabel: '1.4m x 0.4m',
    width: 1.4,
    height: 0.4,
    tags: ['Living'],
  ),
  FurnitureSpec(
    name: 'Refrigerator',
    sizeLabel: '0.9m x 0.75m',
    width: 0.9,
    height: 0.75,
    tags: ['Kitchen'],
  ),
  FurnitureSpec(
    name: 'Stove',
    sizeLabel: '0.8m x 0.6m',
    width: 0.8,
    height: 0.6,
    tags: ['Kitchen'],
  ),
  FurnitureSpec(
    name: 'Sink',
    sizeLabel: '0.8m x 0.5m',
    width: 0.8,
    height: 0.5,
    tags: ['Kitchen', 'Bathroom'],
  ),
  FurnitureSpec(
    name: 'Toilet',
    sizeLabel: '0.7m x 0.5m',
    width: 0.7,
    height: 0.5,
    tags: ['Bathroom'],
  ),
  FurnitureSpec(
    name: 'Shower',
    sizeLabel: '0.9m x 0.9m',
    width: 0.9,
    height: 0.9,
    tags: ['Bathroom'],
  ),
];
