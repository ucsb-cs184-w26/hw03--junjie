import 'package:flutter/material.dart';

import '../models/floor_plan.dart';
import '../models/furniture.dart';
import '../utils/geometry.dart';
import 'floor_plan_painter.dart';
import 'placed_furniture_widget.dart';

class PlanCanvas extends StatelessWidget {
  const PlanCanvas({
    super.key,
    required this.plan,
    required this.placedItems,
    required this.onDrop,
    required this.onMove,
    required this.selectedItemId,
    required this.onSelectItem,
  });

  final FloorPlan plan;
  final List<PlacedFurniture> placedItems;
  final void Function(FurnitureSpec spec, Offset planPosition) onDrop;
  final void Function(String id, Offset newPosition) onMove;
  final String? selectedItemId;
  final ValueChanged<String> onSelectItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.45,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size size = constraints.biggest;
            final PlanTransform transform = computePlanTransform(size, plan);
            return DragTarget<FurnitureSpec>(
              onWillAccept: (data) => data != null,
              onAcceptWithDetails: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset local = box.globalToLocal(details.offset);
                final Offset planPos = transform.fromCanvas(local);
                onDrop(details.data, planPos);
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FloorPlanPainter(plan, transform),
                      ),
                    ),
                    for (final item in placedItems)
                      PlacedFurnitureWidget(
                        item: item,
                        transform: transform,
                        onMove: onMove,
                        isSelected: item.id == selectedItemId,
                        onSelect: () => onSelectItem(item.id),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
