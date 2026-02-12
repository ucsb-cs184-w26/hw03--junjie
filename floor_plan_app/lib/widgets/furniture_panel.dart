import 'package:flutter/material.dart';
import '../models/floor_plan.dart';

class FurniturePanel extends StatelessWidget {
  const FurniturePanel({super.key});

  static const Map<String, Color> _categoryColors = {
    'bedroom': Color(0xFFC8E6C9),
    'living': Color(0xFFBBDEFB),
    'kitchen': Color(0xFFFFE0B2),
    'bathroom': Color(0xFFB2EBF2),
  };

  static const Map<String, IconData> _itemIcons = {
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

  @override
  Widget build(BuildContext context) {
    final items = FurnitureCatalog.items;
    final grouped = <String, List<FurnitureItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.indigo,
            child: const Text(
              'Furniture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: grouped.entries.map((entry) {
                return _CategorySection(
                  category: entry.key,
                  items: entry.value,
                  categoryColors: _categoryColors,
                  itemIcons: _itemIcons,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<FurnitureItem> items;
  final Map<String, Color> categoryColors;
  final Map<String, IconData> itemIcons;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.categoryColors,
    required this.itemIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            category[0].toUpperCase() + category.substring(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        ...items.map((item) => _DraggableFurnitureTile(
          item: item,
          color: categoryColors[item.category] ?? Colors.grey[300]!,
          icon: itemIcons[item.id] ?? Icons.square_outlined,
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DraggableFurnitureTile extends StatelessWidget {
  final FurnitureItem item;
  final Color color;
  final IconData icon;

  const _DraggableFurnitureTile({
    required this.item,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<FurnitureItem>(
      data: item,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black38),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _tileContent(),
      ),
      child: _tileContent(),
    );
  }

  Widget _tileContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            '${item.gridWidth.toInt()}x${item.gridHeight.toInt()}',
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
