import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'services/floor_plan_parser.dart';
import 'models/floor_plan.dart';
import 'widgets/floor_plan_view.dart';
import 'widgets/furniture_panel.dart';

void main() {
  runApp(const FloorPlanApp());
}

class FloorPlanApp extends StatelessWidget {
  const FloorPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floor Plan Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const FloorPlanScreen(),
    );
  }
}

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  late Future<FloorPlan> _floorPlanFuture;
  final List<FurnitureItem> _placedFurniture = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _floorPlanFuture = _loadFloorPlan();
  }

  Future<FloorPlan> _loadFloorPlan() async {
    final xmlString = await rootBundle.loadString('assets/floor_plan.xml');
    return FloorPlanParser.parse(xmlString);
  }

  void _onFurnitureDropped(FurnitureItem item, Offset gridPosition) {
    setState(() {
      _placedFurniture.add(FurnitureItem(
        id: item.id,
        name: item.name,
        category: item.category,
        gridWidth: item.gridWidth,
        gridHeight: item.gridHeight,
        x: gridPosition.dx,
        y: gridPosition.dy,
      ));
      _nextId++;
    });
  }

  void _onFurnitureMoved(int index, Offset newGridPosition) {
    setState(() {
      if (index >= 0 && index < _placedFurniture.length) {
        final item = _placedFurniture[index];
        _placedFurniture[index] = item.copyWith(
          x: newGridPosition.dx,
          y: newGridPosition.dy,
        );
      }
    });
  }

  void _onFurnitureRemoved(int index) {
    setState(() {
      if (index >= 0 && index < _placedFurniture.length) {
        _placedFurniture.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan'),
        centerTitle: true,
        actions: [
          if (_placedFurniture.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() => _placedFurniture.clear());
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              label: const Text('Clear All',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: Row(
        children: [
          const FurniturePanel(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<FloorPlan>(
                future: _floorPlanFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: FloorPlanView(
                          floorPlan: snapshot.data!,
                          placedFurniture: _placedFurniture,
                          onFurnitureDropped: _onFurnitureDropped,
                          onFurnitureMoved: _onFurnitureMoved,
                          onFurnitureRemoved: _onFurnitureRemoved,
                        ),
                      ),
                      if (_placedFurniture.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_placedFurniture.length} item(s) placed  |  Double-click to remove  |  Drag to reposition',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
