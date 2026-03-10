import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import 'package:chef_plannet/theme/app_theme.dart';
import 'package:chef_plannet/theme/app_router.dart';
import 'package:chef_plannet/services/mongodb_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:chef_plannet/providers/cart_provider.dart';
import 'package:chef_plannet/providers/auth_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar text to dark by default (since background is light)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light background
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white, // Light nav bar
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

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

  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const ChefPlanetApp(),
    ),
  );
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
