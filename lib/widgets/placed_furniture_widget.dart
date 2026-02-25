import 'package:flutter/material.dart';

import '../models/furniture.dart';
import '../utils/formatters.dart';
import '../utils/geometry.dart';

class PlacedFurnitureWidget extends StatefulWidget {
  const PlacedFurnitureWidget({
    super.key,
    required this.item,
    required this.transform,
    required this.onMove,
    required this.isSelected,
    required this.onSelect,
  });

  final PlacedFurniture item;
  final PlanTransform transform;
  final void Function(String id, Offset newPosition) onMove;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  State<PlacedFurnitureWidget> createState() => _PlacedFurnitureWidgetState();
}

class _PlacedFurnitureWidgetState extends State<PlacedFurnitureWidget> {
  bool _showLabel = false;

  void _setLabelVisible(bool visible) {
    if (_showLabel == visible) return;
    setState(() {
      _showLabel = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Rect rect = widget.transform.toCanvas(widget.item.rect);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: MouseRegion(
        onEnter: (_) => _setLabelVisible(true),
        onExit: (_) => _setLabelVisible(false),
        child: GestureDetector(
          onTap: widget.onSelect,
          onLongPressStart: (_) => _setLabelVisible(true),
          onLongPressEnd: (_) => _setLabelVisible(false),
          onPanUpdate: (details) {
            final double scale = widget.transform.scale;
            final Offset deltaPlan =
                Offset(details.delta.dx / scale, details.delta.dy / scale);
            widget.onMove(widget.item.id, widget.item.position + deltaPlan);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: widget.item.rotation,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A74FF).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isSelected
                          ? const Color(0xFF2D1FA6)
                          : const Color(0xFF4C3FB4),
                      width: widget.isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -2,
                top: -28,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: (_showLabel || widget.isSelected) ? 1 : 0,
                    duration: const Duration(milliseconds: 140),
                    child: _FurnitureLabel(spec: widget.item.spec),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FurnitureLabel extends StatelessWidget {
  const _FurnitureLabel({required this.spec});

  final FurnitureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4C3FB4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          Text(
            '${formatMeters(spec.width)}m x ${formatMeters(spec.height)}m',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
