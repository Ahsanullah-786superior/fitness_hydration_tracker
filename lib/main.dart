import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/fitness_provider.dart';
import 'providers/water_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const FitnessHydrationApp());
}

class FitnessHydrationApp extends StatelessWidget {
  const FitnessHydrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FitnessProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => WaterProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Fitness & Hydration Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
