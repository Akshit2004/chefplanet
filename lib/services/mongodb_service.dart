import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';
import '../models/dish_model.dart';

class MongoDatabase {
  static final Logger _logger = Logger('MongoDatabase');

  // Cache the URI after first successful load
  static String? _cachedUri;

  static String get connectionString {
    if (_cachedUri != null) return _cachedUri!;
    try {
      _cachedUri = dotenv.env['MONGODB_URI'] ?? '';
    } catch (_) {
      // dotenv not initialized yet — return empty
      return '';
    }
    return _cachedUri!;
  }

  static Db? _db;

  static Future<void> connect() async {
    // If already connected, skip
    if (_db != null && _db!.isConnected) return;

    // Reset any stale/broken connection
    _db = null;

    // Ensure dotenv is loaded
    try {
      await dotenv.load(fileName: ".env");
      _cachedUri = dotenv.env['MONGODB_URI'] ?? '';
    } catch (_) {
      // Already loaded or file issue — use cached
    }

    final uri = connectionString;
    if (uri.isEmpty) {
      _logger.severe('MONGODB_URI is empty — check your .env file');
      return;
    }

    try {
      _logger.info('Connecting to MongoDB...');
      _db = await Db.create(uri);
      await _db!.open().timeout(const Duration(seconds: 30));
      _logger.info('Connected to MongoDB successfully');
    } catch (e) {
      _logger.severe('Could not connect to MongoDB: $e');
      _db = null;
    }
  }

  static Future<List<Category>> getCategories() async {
    await connect();
    if (_db == null || !_db!.isConnected) return [];
    try {
      final collection = _db!.collection('categories');
      final categories = await collection.find().toList();
      _logger.info('Fetched ${categories.length} categories');
      return categories.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching categories: $e');
      return [];
    }
  }

  static Future<List<Dish>> getFeaturedDishes() async {
    await connect();
    if (_db == null || !_db!.isConnected) return [];
    try {
      final collection = _db!.collection('dishes');
      final dishes = await collection.find().toList();
      _logger.info('Fetched ${dishes.length} dishes');
      return dishes.map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching dishes: $e');
      return [];
    }
  }

  static Future<Dish?> getDishById(String id) async {
    await connect();
    if (_db == null || !_db!.isConnected) return null;
    try {
      final collection = _db!.collection('dishes');
      final dishJson = await collection.findOne(where.eq('_id', id));
      if (dishJson != null) {
        return Dish.fromJson(dishJson);
      }
    } catch (e) {
      _logger.warning('Error finding dish: $e');
    }
    return null;
  }
}
