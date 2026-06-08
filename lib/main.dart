import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/strings.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const ProviderScope(child: VirtualWalkerApp()));
}

class VirtualWalkerApp extends StatelessWidget {
  const VirtualWalkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
