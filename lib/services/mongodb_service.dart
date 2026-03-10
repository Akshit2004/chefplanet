import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';
import '../models/dish_model.dart';

class MongoDatabase {
  static final Logger _logger = Logger('MongoDatabase');
  
  static String get connectionString => dotenv.env['MONGODB_URI'] ?? '';

  static Db? _db;

  static Future<void> connect() async {
    if (_db != null && _db!.state == DbState.open) return;
    try {
      _db = await Db.create(connectionString);
      await _db!.open().timeout(const Duration(seconds: 3));
      _logger.info('Connected to MongoDB');
    } catch (e) {
      _logger.severe('Could not connect to MongoDB: $e');
    }
  }

  static Future<List<Category>> getCategories() async {
    if (_db == null) return [];
    try {
      final collection = _db!.collection('categories');
      final categories = await collection.find().toList();
      return categories.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching categories: $e');
      return [];
    }
  }

  static Future<List<Dish>> getFeaturedDishes() async {
    if (_db == null) return [];
    try {
      final collection = _db!.collection('dishes');
      // For now, returning all dishes as featured
      final dishes = await collection.find().toList();
      return dishes.map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching dishes: $e');
      return [];
    }
  }

  static Future<Dish?> getDishById(String id) async {
    if (_db == null) return null;
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
