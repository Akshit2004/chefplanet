import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import 'theme/app_theme.dart';
import 'theme/app_router.dart';
import 'services/mongodb_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
    );
  });

  await dotenv.load(fileName: ".env");
  debugPrint('MONGODB_URI loaded: ${dotenv.env['MONGODB_URI'] != null ? 'yes (${dotenv.env['MONGODB_URI']!.length} chars)' : 'NO — .env not loaded!'}');

  await MongoDatabase.connect();
  runApp(const ChefPlanetApp());
}

class ChefPlanetApp extends StatelessWidget {
  const ChefPlanetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chef Planet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
