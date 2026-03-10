import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_router.dart';
import 'services/mongodb_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
