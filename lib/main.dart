import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

void main() {
  runApp(const FloorPlannerApp());
}

const Color kPageBackground = Color(0xFFE7E8E2);
const Color kPanelBackground = Color(0xFFE1E2DB);
const Color kAccentPurple = Color(0xFF5B4BB2);
const Color kWallColor = Color(0xFFB56A61);
const Color kDoorColor = Color(0xFFC78B83);

const String kDefaultPlanJson = '''
{
  "floorPlan": {
    "@attributes": {
      "width": "20",
      "height": "14"
    },
    "rooms": {
      "room": [
        {
          "@attributes": {
            "id": "living_room",
            "type": "living"
          },
          "name": "Living Room",
          "position": {
            "@attributes": {
              "x": "0",
              "y": "0",
              "width": "12",
              "height": "7"
            }
          },
          "adjacentTo": [
            "kitchen",
            "bedroom_1",
            "bedroom_2"
          ]
        },
        {
          "@attributes": {
            "id": "kitchen",
            "type": "kitchen"
          },
          "name": "Kitchen",
          "position": {
            "@attributes": {
              "x": "12",
              "y": "0",
              "width": "8",
              "height": "4"
            }
          },
          "adjacentTo": [
            "living_room",
            "bedroom_1"
          ]
        },
        {
          "@attributes": {
            "id": "bedroom_1",
            "type": "bedroom"
          },
          "name": "BR1",
          "position": {
            "@attributes": {
              "x": "12",
              "y": "4",
              "width": "8",
              "height": "5"
            }
          },
          "adjacentTo": [
            "living_room",
            "kitchen",
            "bathroom_1",
            "bathroom_2"
          ]
        },
        {
          "@attributes": {
            "id": "bathroom_1",
            "type": "bathroom"
          },
          "name": "Bath1",
          "position": {
            "@attributes": {
              "x": "17",
              "y": "4",
              "width": "3",
              "height": "5"
            }
          },
          "adjacentTo": "bedroom_1"
        },
        {
          "@attributes": {
            "id": "bedroom_2",
            "type": "bedroom"
          },
          "name": "BR2",
          "position": {
            "@attributes": {
              "x": "0",
              "y": "7",
              "width": "12",
              "height": "7"
            }
          },
          "adjacentTo": [
            "living_room",
            "bathroom_2"
          ]
        },
        {
          "@attributes": {
            "id": "bathroom_2",
            "type": "bathroom"
          },
          "name": "Bath2",
          "position": {
            "@attributes": {
              "x": "12",
              "y": "9",
              "width": "8",
              "height": "5"
            }
          },
          "adjacentTo": [
            "bedroom_1",
            "bedroom_2"
          ]
        }
      ]
    }
  }
}
''';

class FloorPlannerApp extends StatelessWidget {
  const FloorPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Floor Planner',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: kPageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccentPurple),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const FloorPlannerHome(),
    );
  }
}

class FloorPlannerHome extends StatefulWidget {
  const FloorPlannerHome({super.key});

  @override
  State<FloorPlannerHome> createState() => _FloorPlannerHomeState();
}

class _FloorPlannerHomeState extends State<FloorPlannerHome> {
  late FloorPlan _plan;
  String _planLabel = 'Loaded bundled JSON floor plan';
  final List<PlacedFurniture> _placedItems = [];
  String? _placementWarning;
  String _selectedTag = 'All';
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _plan = parsePlanFromJson(kDefaultPlanJson);
  }

  Future<void> _importPlan() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'xml'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.single;
      String contents;
      if (file.path != null) {
        contents = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        contents = utf8.decode(file.bytes!);
      } else {
        throw const FormatException('No readable file contents found.');
      }

      final String name = file.name;
      final String ext = _fileExtension(name);
      FloorPlan plan;
      if (ext == 'json') {
        plan = parsePlanFromJson(contents);
      } else if (ext == 'xml') {
        plan = parsePlanFromXml(contents);
      } else {
        plan = contents.trimLeft().startsWith('<')
            ? parsePlanFromXml(contents)
            : parsePlanFromJson(contents);
      }

      if (!mounted) return;
      setState(() {
        _plan = plan;
        _planLabel = 'Loaded $name';
        _placedItems.clear();
        _placementWarning = null;
        _selectedItemId = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tags = _buildTagList();
    final List<FurnitureSpec> filteredItems = _selectedTag == 'All'
        ? kFurnitureCatalog
        : kFurnitureCatalog
            .where((item) => item.tags.contains(_selectedTag))
            .toList();
    final PlacedFurniture? selectedItem = _getSelectedItem();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                SizedBox(
                  width: 300,
                  child: FurniturePanel(
                    items: filteredItems,
                    tags: tags,
                    selectedTag: _selectedTag,
                    onTagSelected: (tag) {
                      setState(() {
                        _selectedTag = tag;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FloorPlanPanel(
                    plan: _plan,
                    statusLabel: _planLabel,
                    onImport: _importPlan,
                    placedItems: _placedItems,
                    onDrop: _handleDrop,
                    onMove: _handleMove,
                    warningText: _placementWarning,
                    selectedItem: selectedItem,
                    onRotate: _handleRotate,
                    onClearSelection: _clearSelection,
                    onSelectItem: _handleSelectItem,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleDrop(FurnitureSpec spec, Offset planPosition) {
    final Offset topLeft = Offset(
      planPosition.dx - spec.width / 2,
      planPosition.dy - spec.height / 2,
    );
    final Rect rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, spec.width, spec.height);
    if (!_isValidPlacement(rect)) {
      setState(() {
        _placementWarning =
            'invalid placement: avoid walls, doorways, and existing furniture';
      });
      return;
    }
    setState(() {
      _placementWarning = null;
      _placedItems.add(
        PlacedFurniture(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}',
          spec: spec,
          position: topLeft,
          rotation: 0,
        ),
      );
      _selectedItemId = _placedItems.last.id;
    });
  }

  void _handleMove(String id, Offset newPosition) {
    final int index = _placedItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final PlacedFurniture item = _placedItems[index];
    final Rect rect =
        Rect.fromLTWH(newPosition.dx, newPosition.dy, item.spec.width, item.spec.height);
    if (!_isValidPlacement(rect, ignoreId: id)) {
      setState(() {
        _placementWarning =
            'invalid placement: avoid walls, doorways, and existing furniture';
      });
      return;
    }
    setState(() {
      _placementWarning = null;
      _placedItems[index] = item.copyWith(position: newPosition);
    });
  }

  void _handleRotate(double degrees) {
    if (_selectedItemId == null) return;
    final int index = _placedItems.indexWhere((item) => item.id == _selectedItemId);
    if (index == -1) return;
    final double radians = degrees * (math.pi / 180);
    setState(() {
      _placedItems[index] = _placedItems[index].copyWith(rotation: radians);
    });
  }

  void _handleSelectItem(String id) {
    setState(() {
      _selectedItemId = id;
    });
  }

  void _clearSelection() {
    if (_selectedItemId == null) return;
    setState(() {
      _selectedItemId = null;
    });
  }

  PlacedFurniture? _getSelectedItem() {
    if (_selectedItemId == null) return null;
    for (final item in _placedItems) {
      if (item.id == _selectedItemId) return item;
    }
    return null;
  }

  List<String> _buildTagList() {
    final Set<String> available = kFurnitureCatalog
        .expand((item) => item.tags)
        .toSet();
    const List<String> tagOrder = [
      'Living',
      'Kitchen',
      'Bedroom',
      'Bathroom',
      'Dining',
      'Office',
    ];
    final List<String> tags = ['All'];
    for (final tag in tagOrder) {
      if (available.contains(tag)) {
        tags.add(tag);
      }
    }
    for (final tag in available) {
      if (!tags.contains(tag)) {
        tags.add(tag);
      }
    }
    return tags;
  }

  bool _isValidPlacement(Rect rect, {String? ignoreId}) {
    final bool insideRoom = _plan.rooms.any(
      (room) =>
          room.rect.contains(rect.topLeft) &&
          room.rect.contains(rect.bottomRight),
    );
    if (!insideRoom) return false;

    for (final door in computeDoorways(_plan)) {
      if (rect.overlaps(door)) return false;
    }

    for (final item in _placedItems) {
      if (ignoreId != null && item.id == ignoreId) continue;
      if (rect.overlaps(item.rect)) return false;
    }

    return true;
  }
}

class FurniturePanel extends StatelessWidget {
  const FurniturePanel({
    super.key,
    required this.items,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  final List<FurnitureSpec> items;
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Furniture', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Actual dimensions (meters)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 20),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: kPanelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String tag = tags[index];
                return ChoiceChip(
                  label: Text(tag),
                  selected: tag == selectedTag,
                  onSelected: (_) => onTagSelected(tag),
                  selectedColor: kAccentPurple.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: tag == selectedTag ? kAccentPurple : Colors.black87,
                    fontWeight: tag == selectedTag ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => FurnitureCard(spec: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

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

class FurnitureCard extends StatelessWidget {
  const FurnitureCard({super.key, required this.spec});

  final FurnitureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Draggable<FurnitureSpec>(
      data: spec,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: _FurnitureCardContent(spec: spec),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _FurnitureCardContent(spec: spec),
      ),
      child: _FurnitureCardContent(spec: spec),
    );
  }
}

class _FurnitureCardContent extends StatelessWidget {
  const _FurnitureCardContent({required this.spec});

  final FurnitureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            spec.sizeLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                ),
          ),
        ],
      ),
    );
  }
}

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
                    value: _radiansToDegrees(selectedItem!.rotation),
                    min: 0,
                    max: 360,
                    onChanged: onRotate,
                  ),
                ),
                Text('${_radiansToDegrees(selectedItem!.rotation).round()}°'),
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
            child: _PlanCanvas(
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

class _PlanCanvas extends StatelessWidget {
  const _PlanCanvas({
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
                      _PlacedFurnitureWidget(
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

class _PlacedFurnitureWidget extends StatefulWidget {
  const _PlacedFurnitureWidget({
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
  State<_PlacedFurnitureWidget> createState() => _PlacedFurnitureWidgetState();
}

class _PlacedFurnitureWidgetState extends State<_PlacedFurnitureWidget> {
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
          final Offset deltaPlan =
              Offset(details.delta.dx / widget.transform.scale, details.delta.dy / widget.transform.scale);
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
            '${_formatMeters(spec.width)}m x ${_formatMeters(spec.height)}m',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter(this.plan, this.transform);

  final FloorPlan plan;
  final PlanTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    Rect toCanvas(Rect rect) => transform.toCanvas(rect);

    final Paint roomPaint = Paint()..style = PaintingStyle.fill;
    final Paint wallPaint = Paint()
      ..color = kWallColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final Paint doorPaint = Paint()
      ..color = kDoorColor
      ..style = PaintingStyle.fill;

    for (final room in plan.rooms) {
      roomPaint.color = _roomColor(room.type);
      canvas.drawRect(toCanvas(room.rect), roomPaint);
    }

    for (final room in plan.rooms) {
      canvas.drawRect(toCanvas(room.rect), wallPaint);
    }

    final Rect planBounds = toCanvas(Rect.fromLTWH(0, 0, plan.width, plan.height));
    canvas.drawRect(planBounds, wallPaint);

    for (final Rect door in computeDoorways(plan)) {
      canvas.drawRect(toCanvas(door), doorPaint);
    }

    final double fontSize = (12 * transform.scale).clamp(10, 18).toDouble();
    for (final room in plan.rooms) {
      _drawLabel(canvas, toCanvas(room.rect), room.name, fontSize);
    }
  }

  Color _roomColor(String type) {
    switch (type.toLowerCase()) {
      case 'living':
        return const Color(0xFFF8EFD3);
      case 'kitchen':
        return const Color(0xFFDCECD8);
      case 'bedroom':
        return const Color(0xFFD9E8F7);
      case 'bathroom':
        return const Color(0xFFD8E4D3);
      default:
        return const Color(0xFFF1EEE6);
    }
  }

  void _drawLabel(Canvas canvas, Rect area, String text, double fontSize) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: area.width - 8);

    final Offset offset = Offset(
      area.center.dx - painter.width / 2,
      area.center.dy - painter.height / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.plan != plan || oldDelegate.transform != transform;
  }
}

class FloorPlan {
  const FloorPlan({
    required this.width,
    required this.height,
    required this.rooms,
  });

  final double width;
  final double height;
  final List<FloorRoom> rooms;
}

class FloorRoom {
  const FloorRoom({
    required this.id,
    required this.type,
    required this.name,
    required this.rect,
    required this.adjacent,
  });

  final String id;
  final String type;
  final String name;
  final Rect rect;
  final List<String> adjacent;
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

class PlanTransform {
  const PlanTransform({
    required this.scale,
    required this.offset,
  });

  final double scale;
  final Offset offset;

  Rect toCanvas(Rect rect) {
    return Rect.fromLTWH(
      offset.dx + rect.left * scale,
      offset.dy + rect.top * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }

  Offset fromCanvas(Offset point) {
    return Offset(
      (point.dx - offset.dx) / scale,
      (point.dy - offset.dy) / scale,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanTransform &&
        other.scale == scale &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(scale, offset);
}

PlanTransform computePlanTransform(Size size, FloorPlan plan) {
  final double pad = size.shortestSide * 0.06;
  final double safeWidth = plan.width <= 0 ? 1 : plan.width;
  final double safeHeight = plan.height <= 0 ? 1 : plan.height;
  final double scale = math.min(
    (size.width - pad * 2) / safeWidth,
    (size.height - pad * 2) / safeHeight,
  );
  final double offsetX = (size.width - safeWidth * scale) / 2;
  final double offsetY = (size.height - safeHeight * scale) / 2;
  return PlanTransform(scale: scale, offset: Offset(offsetX, offsetY));
}

List<Rect> computeDoorways(FloorPlan plan) {
  final Map<String, FloorRoom> byId = {
    for (final room in plan.rooms) room.id: room,
  };
  final Set<String> visited = {};
  final List<Rect> doors = [];
  final double base = math.min(plan.width, plan.height);

  for (final room in plan.rooms) {
    for (final adjacent in room.adjacent) {
      final FloorRoom? other = byId[adjacent];
      if (other == null) continue;

      final String key = room.id.compareTo(other.id) < 0
          ? '${room.id}|${other.id}'
          : '${other.id}|${room.id}';
      if (!visited.add(key)) continue;

      final Rect? door = _sharedDoorwayRect(room.rect, other.rect, base);
      if (door != null) {
        doors.add(door);
      }
    }
  }

  return doors;
}

Rect? _sharedDoorwayRect(Rect a, Rect b, double base) {
  const double epsilon = 1e-6;
  final double doorThickness = base * 0.02;
  final double maxDoorLength = base * 0.08;

  if ((a.right - b.left).abs() < epsilon || (b.right - a.left).abs() < epsilon) {
    final double edgeX = (a.right - b.left).abs() < epsilon ? a.right : b.right;
    final double overlapTop = math.max(a.top, b.top);
    final double overlapBottom = math.min(a.bottom, b.bottom);
    final double overlap = overlapBottom - overlapTop;
    if (overlap <= 0) return null;
    final double doorLength = math.min(maxDoorLength, overlap * 0.6);
    final double centerY = (overlapTop + overlapBottom) / 2;
    return Rect.fromCenter(
      center: Offset(edgeX, centerY),
      width: doorThickness,
      height: doorLength,
    );
  }

  if ((a.bottom - b.top).abs() < epsilon || (b.bottom - a.top).abs() < epsilon) {
    final double edgeY = (a.bottom - b.top).abs() < epsilon ? a.bottom : b.bottom;
    final double overlapLeft = math.max(a.left, b.left);
    final double overlapRight = math.min(a.right, b.right);
    final double overlap = overlapRight - overlapLeft;
    if (overlap <= 0) return null;
    final double doorLength = math.min(maxDoorLength, overlap * 0.6);
    final double centerX = (overlapLeft + overlapRight) / 2;
    return Rect.fromCenter(
      center: Offset(centerX, edgeY),
      width: doorLength,
      height: doorThickness,
    );
  }

  return null;
}

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
    final Map<String, dynamic> roomMap =
        roomsList[i] as Map<String, dynamic>;
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

String _fileExtension(String name) {
  final List<String> parts = name.split('.');
  if (parts.length < 2) return '';
  return parts.last.toLowerCase();
}

String _formatMeters(double value) {
  final String fixed = value.toStringAsFixed(2);
  final String trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return trimmed;
}

double _radiansToDegrees(double radians) {
  final double deg = radians * (180 / math.pi);
  final double normalized = deg % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}
