class FloorPlan {
  final double width;
  final double height;
  final List<Room> rooms;

  FloorPlan({
    required this.width,
    required this.height,
    required this.rooms,
  });
}

class Room {
  final String id;
  final String type;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final List<String> adjacentTo;

  Room({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.adjacentTo,
  });
}

class FurnitureItem {
  final String id;
  final String name;
  final String category;
  final double gridWidth;
  final double gridHeight;
  double x;
  double y;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.category,
    required this.gridWidth,
    required this.gridHeight,
    this.x = 0,
    this.y = 0,
  });

  FurnitureItem copyWith({double? x, double? y}) {
    return FurnitureItem(
      id: id,
      name: name,
      category: category,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class FurnitureCatalog {
  static List<FurnitureItem> get items => [
    FurnitureItem(id: 'twin_bed', name: 'Twin Bed', category: 'bedroom', gridWidth: 2, gridHeight: 3),
    FurnitureItem(id: 'queen_bed', name: 'Queen Bed', category: 'bedroom', gridWidth: 3, gridHeight: 3),
    FurnitureItem(id: 'king_bed', name: 'King Bed', category: 'bedroom', gridWidth: 4, gridHeight: 3),
    FurnitureItem(id: 'sofa', name: 'Sofa', category: 'living', gridWidth: 4, gridHeight: 2),
    FurnitureItem(id: 'armchair', name: 'Armchair', category: 'living', gridWidth: 2, gridHeight: 2),
    FurnitureItem(id: 'dining_table', name: 'Dining Table', category: 'kitchen', gridWidth: 3, gridHeight: 2),
    FurnitureItem(id: 'desk', name: 'Desk', category: 'bedroom', gridWidth: 3, gridHeight: 1.5),
    FurnitureItem(id: 'wardrobe', name: 'Wardrobe', category: 'bedroom', gridWidth: 3, gridHeight: 1),
    FurnitureItem(id: 'bathtub', name: 'Bathtub', category: 'bathroom', gridWidth: 2, gridHeight: 3),
    FurnitureItem(id: 'toilet', name: 'Toilet', category: 'bathroom', gridWidth: 1, gridHeight: 1.5),
    FurnitureItem(id: 'tv_stand', name: 'TV Stand', category: 'living', gridWidth: 3, gridHeight: 1),
    FurnitureItem(id: 'coffee_table', name: 'Coffee Table', category: 'living', gridWidth: 2, gridHeight: 1),
  ];
}
