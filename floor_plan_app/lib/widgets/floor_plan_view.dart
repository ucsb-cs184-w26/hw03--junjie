import 'package:flutter/material.dart';
import '../models/floor_plan.dart';

class FloorPlanView extends StatefulWidget {
  final FloorPlan floorPlan;
  final List<FurnitureItem> placedFurniture;
  final void Function(FurnitureItem item, Offset position) onFurnitureDropped;
  final void Function(int index, Offset newPosition) onFurnitureMoved;
  final void Function(int index) onFurnitureRemoved;

  const FloorPlanView({
    super.key,
    required this.floorPlan,
    required this.placedFurniture,
    required this.onFurnitureDropped,
    required this.onFurnitureMoved,
    required this.onFurnitureRemoved,
  });

  @override
  State<FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<FloorPlanView> {
  final GlobalKey _floorPlanKey = GlobalKey();

  Color _roomColor(String type) {
    switch (type) {
      case 'living':
        return const Color(0xFFBBDEFB);
      case 'kitchen':
        return const Color(0xFFFFE0B2);
      case 'bedroom':
        return const Color(0xFFC8E6C9);
      case 'bathroom':
        return const Color(0xFFB2EBF2);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  IconData _roomIcon(String type) {
    switch (type) {
      case 'living':
        return Icons.weekend;
      case 'kitchen':
        return Icons.kitchen;
      case 'bedroom':
        return Icons.bed;
      case 'bathroom':
        return Icons.bathtub;
      default:
        return Icons.room;
    }
  }

  static const Map<String, IconData> _furnitureIcons = {
    'twin_bed': Icons.single_bed,
    'queen_bed': Icons.bed,
    'king_bed': Icons.king_bed,
    'sofa': Icons.weekend,
    'armchair': Icons.chair,
    'dining_table': Icons.table_restaurant,
    'desk': Icons.desk,
    'wardrobe': Icons.checkroom,
    'bathtub': Icons.bathtub,
    'toilet': Icons.wash,
    'tv_stand': Icons.tv,
    'coffee_table': Icons.table_bar,
  };

  static const Map<String, Color> _furnitureColors = {
    'bedroom': Color(0xFF81C784),
    'living': Color(0xFF64B5F6),
    'kitchen': Color(0xFFFFB74D),
    'bathroom': Color(0xFF4DD0E1),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / widget.floorPlan.width;
        final cellH = constraints.maxHeight / widget.floorPlan.height;
        final cellSize = cellW < cellH ? cellW : cellH;

        final totalW = cellSize * widget.floorPlan.width;
        final totalH = cellSize * widget.floorPlan.height;

        return Center(
          child: DragTarget<FurnitureItem>(
            onAcceptWithDetails: (details) {
              final renderBox = _floorPlanKey.currentContext!
                  .findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.offset);
              final gridX = localPos.dx / cellSize;
              final gridY = localPos.dy / cellSize;
              widget.onFurnitureDropped(
                details.data,
                Offset(gridX, gridY),
              );
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Container(
                key: _floorPlanKey,
                width: totalW,
                height: totalH,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isHovering ? Colors.indigo : Colors.black87,
                    width: isHovering ? 4 : 3,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Rooms
                    ...widget.floorPlan.rooms.map((room) {
                      return Positioned(
                        left: room.x * cellSize,
                        top: room.y * cellSize,
                        width: room.width * cellSize,
                        height: room.height * cellSize,
                        child: _RoomTile(
                          room: room,
                          color: _roomColor(room.type),
                          icon: _roomIcon(room.type),
                        ),
                      );
                    }),
                    // Placed furniture
                    ...widget.placedFurniture.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final icon = _furnitureIcons[item.id] ?? Icons.square_outlined;
                      final color = _furnitureColors[item.category] ?? Colors.grey;

                      return Positioned(
                        left: item.x * cellSize,
                        top: item.y * cellSize,
                        width: item.gridWidth * cellSize,
                        height: item.gridHeight * cellSize,
                        child: _PlacedFurniture(
                          item: item,
                          index: index,
                          icon: icon,
                          color: color,
                          cellSize: cellSize,
                          floorPlanKey: _floorPlanKey,
                          onMoved: widget.onFurnitureMoved,
                          onRemoved: widget.onFurnitureRemoved,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlacedFurniture extends StatelessWidget {
  final FurnitureItem item;
  final int index;
  final IconData icon;
  final Color color;
  final double cellSize;
  final GlobalKey floorPlanKey;
  final void Function(int index, Offset newPosition) onMoved;
  final void Function(int index) onRemoved;

  const _PlacedFurniture({
    required this.item,
    required this.index,
    required this.icon,
    required this.color,
    required this.cellSize,
    required this.floorPlanKey,
    required this.onMoved,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final w = item.gridWidth * cellSize;
    final h = item.gridHeight * cellSize;

    return GestureDetector(
      onDoubleTap: () => onRemoved(index),
      child: Draggable<_MovingFurniture>(
        data: _MovingFurniture(index: index, item: item),
        feedback: Material(
          elevation: 8,
          color: Colors.transparent,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black45, width: 2),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey, width: 1, style: BorderStyle.solid),
          ),
        ),
        onDragEnd: (details) {
          final renderBox = floorPlanKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localPos = renderBox.globalToLocal(details.offset);
          final gridX = localPos.dx / cellSize;
          final gridY = localPos.dy / cellSize;
          onMoved(index, Offset(gridX, gridY));
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black45, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              if (h > 30)
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovingFurniture {
  final int index;
  final FurnitureItem item;
  _MovingFurniture({required this.index, required this.item});
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final Color color;
  final IconData icon;

  const _RoomTile({
    required this.room,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black54, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.black54),
            const SizedBox(height: 4),
            Text(
              room.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
