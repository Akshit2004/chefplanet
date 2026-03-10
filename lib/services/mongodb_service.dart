import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';

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

  static Future<List<Dish>> getDishesByCategory(String categoryId) async {
    await connect();
    if (_db == null || !_db!.isConnected) return [];
    try {
      final collection = _db!.collection('dishes');
      final dishes = await collection.find(where.eq('categoryId', categoryId)).toList();
      _logger.info('Fetched ${dishes.length} dishes for category $categoryId');
      return dishes.map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching dishes for category $categoryId: $e');
      return [];
    }
  }

  // --- User Authentication ---

  static Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await connect();
    if (_db == null || !_db!.isConnected) return null;

    try {
      final collection = _db!.collection('users');
      
      // Check if user already exists
      final existingUser = await collection.findOne(where.eq('email', email));
      if (existingUser != null) {
        return {'error': 'User already exists'};
      }

      final userData = {
        '_id': ObjectId(),
        'name': name,
        'email': email,
        'password': password, // Note: In a real app, hash this!
        'createdAt': DateTime.now().toIso8601String(),
      };

      await collection.insertOne(userData);
      _logger.info('User registered successfully: $email');
      return userData;
    } catch (e) {
      _logger.severe('Error registering user: $e');
      return {'error': 'Registration failed'};
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    await connect();
    if (_db == null || !_db!.isConnected) return null;

    try {
      final collection = _db!.collection('users');
      final user = await collection.findOne(
        where.eq('email', email).and(where.eq('password', password)),
      );

      if (user != null) {
        _logger.info('User logged in successfully: $email');
        return user;
      }
      return {'error': 'Invalid email or password'};
    } catch (e) {
      _logger.severe('Error logging in user: $e');
      return {'error': 'Login failed'};
    }
  }

  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
  }) async {
    await connect();
    if (_db == null || !_db!.isConnected) return false;

    try {
      final collection = _db!.collection('users');
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      if (updateData.isEmpty) return true;

      var updateModifier = modify;
      updateData.forEach((key, value) {
        updateModifier = updateModifier.set(key, value);
      });

      await collection.updateOne(
        where.id(ObjectId.fromHexString(userId)),
        updateModifier,
      );
      _logger.info('User profile updated: $userId');
      return true;
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      return false;
    }
  }

  static Future<List<Order>> getUserOrders(String userId) async {
    await connect();
    if (_db == null || !_db!.isConnected) return [];
    try {
      final collection = _db!.collection('orders');
      final orders = await collection.find(where.eq('userId', userId)).toList();
      return orders.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching user orders: $e');
      return [];
    }
  }

  static Future<List<Address>> getUserAddresses(String userId) async {
    await connect();
    if (_db == null || !_db!.isConnected) return [];
    try {
      final collection = _db!.collection('addresses');
      final addresses = await collection.find(where.eq('userId', userId)).toList();
      return addresses.map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      _logger.warning('Error fetching user addresses: $e');
      return [];
    }
  }

  static Future<bool> addAddress({
    required String userId,
    required String label,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    bool isDefault = false,
  }) async {
    await connect();
    if (_db == null || !_db!.isConnected) return false;
    try {
      final collection = _db!.collection('addresses');
      
      // If this is the only address, make it default automatically
      final count = await collection.count(where.eq('userId', userId));
      if (count == 0) {
        isDefault = true;
      }

      // If it is set as default, we need to clear the default flag on other addresses
      if (isDefault) {
        await collection.updateMany(
          where.eq('userId', userId),
          modify.set('isDefault', false),
        );
      }

      final addressData = {
        '_id': ObjectId(),
        'userId': userId,
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'isDefault': isDefault,
      };
      await collection.insertOne(addressData);
      return true;
    } catch (e) {
      _logger.severe('Error adding address: $e');
      return false;
    }
  }

  static Future<bool> setDefaultAddress(String userId, String addressId) async {
    await connect();
    if (_db == null || !_db!.isConnected) return false;
    try {
      final collection = _db!.collection('addresses');
      
      // Clear default flag for all addresses of this user
      await collection.updateMany(
        where.eq('userId', userId),
        modify.set('isDefault', false),
      );

      // Set the specified address to default
      await collection.updateOne(
        where.id(ObjectId.fromHexString(addressId)).and(where.eq('userId', userId)),
        modify.set('isDefault', true),
      );

      return true;
    } catch (e) {
      _logger.severe('Error setting default address: $e');
      return false;
    }
  }

  static Future<bool> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    await connect();
    if (_db == null || !_db!.isConnected) return false;
    try {
      final collection = _db!.collection('orders');
      final orderData = {
        '_id': ObjectId(),
        'userId': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'status': 'Processing',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await collection.insertOne(orderData);
      return true;
    } catch (e) {
      _logger.severe('Error creating order: $e');
      return false;
    }
  }
}
