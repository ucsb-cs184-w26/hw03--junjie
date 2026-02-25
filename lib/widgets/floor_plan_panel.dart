import 'package:flutter/material.dart';

import '../models/floor_plan.dart';
import '../models/furniture.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import 'plan_canvas.dart';

class FloorPlanPanel extends StatelessWidget {
  const FloorPlanPanel({
    super.key,
    required this.plan,
    required this.statusLabel,
    required this.onImport,
    required this.placedItems,
    required this.onDrop,
    required this.onMove,
    required this.warningText,
    required this.selectedItem,
    required this.onRotate,
    required this.onClearSelection,
    required this.onSelectItem,
  });

  final FloorPlan plan;
  final String statusLabel;
  final VoidCallback onImport;
  final List<PlacedFurniture> placedItems;
  final void Function(FurnitureSpec spec, Offset planPosition) onDrop;
  final void Function(String id, Offset newPosition) onMove;
  final String? warningText;
  final PlacedFurniture? selectedItem;
  final ValueChanged<double> onRotate;
  final VoidCallback onClearSelection;
  final ValueChanged<String> onSelectItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Floor Plan', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              ElevatedButton(
                onPressed: onImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentPurple,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Import JSON/XML'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.65),
                ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 6),
            Text(
              warningText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (selectedItem != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Rotation'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: radiansToDegrees(selectedItem!.rotation),
                    min: 0,
                    max: 360,
                    onChanged: onRotate,
                  ),
                ),
                Text('${radiansToDegrees(selectedItem!.rotation).round()}°'),
                IconButton(
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear selection',
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: PlanCanvas(
              plan: plan,
              placedItems: placedItems,
              onDrop: onDrop,
              onMove: onMove,
              selectedItemId: selectedItem?.id,
              onSelectItem: onSelectItem,
            ),
          ),
        ],
      ),
    );
  }
}
