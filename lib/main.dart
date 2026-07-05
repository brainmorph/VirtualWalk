import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/strings.dart';
import 'screens/map_screen.dart';
import 'services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opened before runApp so gpsSettingsProvider can read it synchronously.
  await Hive.initFlutter();
  await Hive.openBox('settings');
  ForegroundService.init();
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
