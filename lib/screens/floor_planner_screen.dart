import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/floor_plan.dart';
import '../models/furniture.dart';
import '../services/plan_parser.dart';
import '../utils/app_constants.dart';
import '../utils/doorways.dart';
import '../utils/formatters.dart';
import '../widgets/floor_plan_panel.dart';
import '../widgets/furniture_panel.dart';

class FloorPlannerScreen extends StatefulWidget {
  const FloorPlannerScreen({super.key});

  @override
  State<FloorPlannerScreen> createState() => _FloorPlannerScreenState();
}

class _FloorPlannerScreenState extends State<FloorPlannerScreen> {
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

  List<FurnitureSpec> get _filteredItems => _selectedTag == 'All'
      ? kFurnitureCatalog
      : kFurnitureCatalog
          .where((item) => item.tags.contains(_selectedTag))
          .toList();

  void _setSelectedTag(String tag) {
    if (tag == _selectedTag) return;
    setState(() {
      _selectedTag = tag;
    });
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
      final String ext = fileExtension(name);
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

  void _showPlacementWarning() {
    if (_placementWarning == kPlacementWarningText) return;
    setState(() {
      _placementWarning = kPlacementWarningText;
    });
  }

  Offset _centeredTopLeft(FurnitureSpec spec, Offset center) {
    return Offset(
      center.dx - spec.width / 2,
      center.dy - spec.height / 2,
    );
  }

  Rect _rectForSpec(FurnitureSpec spec, Offset topLeft) {
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, spec.width, spec.height);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tags = _buildTagList();
    final List<FurnitureSpec> filteredItems = _filteredItems;
    final PlacedFurniture? selectedItem = _getSelectedItem();

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: FurniturePanel(
                items: filteredItems,
                tags: tags,
                selectedTag: _selectedTag,
                onTagSelected: _setSelectedTag,
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
        ),
      ),
    );
  }

  void _handleDrop(FurnitureSpec spec, Offset planPosition) {
    final Offset topLeft = _centeredTopLeft(spec, planPosition);
    final Rect rect = _rectForSpec(spec, topLeft);
    if (!_isValidPlacement(rect)) {
      _showPlacementWarning();
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
    final Rect rect = _rectForSpec(item.spec, newPosition);
    if (!_isValidPlacement(rect, ignoreId: id)) {
      _showPlacementWarning();
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
    final double radians = degreesToRadians(degrees);
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
    final List<String> tags = ['All'];
    for (final tag in kTagOrder) {
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
    return _isInsideAnyRoom(rect) &&
        !_overlapsDoorway(rect) &&
        !_overlapsExistingFurniture(rect, ignoreId: ignoreId);
  }

  bool _isInsideAnyRoom(Rect rect) {
    return _plan.rooms.any(
      (room) =>
          room.rect.contains(rect.topLeft) &&
          room.rect.contains(rect.bottomRight),
    );
  }

  bool _overlapsDoorway(Rect rect) {
    for (final door in computeDoorways(_plan)) {
      if (rect.overlaps(door)) return true;
    }
    return false;
  }

  bool _overlapsExistingFurniture(Rect rect, {String? ignoreId}) {
    for (final item in _placedItems) {
      if (ignoreId != null && item.id == ignoreId) continue;
      if (rect.overlaps(item.rect)) return true;
    }
    return false;
  }
}
