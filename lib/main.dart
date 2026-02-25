import 'package:flutter/material.dart';

import 'screens/floor_planner_screen.dart';
import 'utils/app_constants.dart';

void main() {
  runApp(const FloorPlannerApp());
}

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
      home: const FloorPlannerScreen(),
    );
  }
}
