import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category_model.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';

class MongoDatabase {
  static final Logger _logger = Logger('MongoDatabase');
  static const String _webUnsupportedMessage =
      'Direct MongoDB access is not supported on Flutter web. Run the app on Windows or Android, or add a backend API.';

  // Cache the URI after first successful load
  static String? _cachedUri;
  static String? _lastError;

  static String? get lastError => _lastError;

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

  static ObjectId? _tryParseObjectId(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return value;

    try {
      return ObjectId.fromHexString(value.toString());
    } catch (_) {
      return null;
    }
  }

  static Future<bool> connect() async {
    if (kIsWeb) {
      _lastError = _webUnsupportedMessage;
      _logger.severe(_webUnsupportedMessage);
      return false;
    }

    // If already connected, skip
    if (_db != null && _db!.isConnected) {
      _lastError = null;
      return true;
    }

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
      _lastError = 'MONGODB_URI is empty. Check your .env file.';
      _logger.severe(_lastError!);
      return false;
    }

    try {
      _logger.info('Connecting to MongoDB...');
      _db = await Db.create(uri);
      await _db!.open().timeout(const Duration(seconds: 30));
      _lastError = null;
      _logger.info('Connected to MongoDB successfully');
      return true;
    } catch (e) {
      _lastError = 'Could not connect to MongoDB. $e';
      _logger.severe('Could not connect to MongoDB: $e');
      _db = null;
      return false;
    }
  }

  static Future<List<Category>> getCategories() async {
    if (!await connect()) return [];

    try {
      final collection = _db!.collection('categories');
      final categories = await collection.find().toList();
      _lastError = null;
      _logger.info('Fetched ${categories.length} categories');
      return categories.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      _lastError = 'Error fetching categories. $e';
      _logger.warning('Error fetching categories: $e');
      return [];
    }
  }

  static Future<List<Dish>> getFeaturedDishes() async {
    if (!await connect()) return [];

    try {
      final collection = _db!.collection('dishes');
      final dishes = await collection.find().toList();
      _lastError = null;
      _logger.info('Fetched ${dishes.length} dishes');
      return dishes.map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      _lastError = 'Error fetching dishes. $e';
      _logger.warning('Error fetching dishes: $e');
      return [];
    }
  }

  static Future<Dish?> getDishById(String id) async {
    if (!await connect()) return null;

    try {
      final collection = _db!.collection('dishes');
      final objectId = _tryParseObjectId(id);
      final dishJson = await collection.findOne(
        objectId != null ? where.id(objectId) : where.eq('_id', id),
      );

      if (dishJson != null) {
        _lastError = null;
        return Dish.fromJson(dishJson);
      }
    } catch (e) {
      _lastError = 'Error finding dish. $e';
      _logger.warning('Error finding dish: $e');
    }
    return null;
  }

  static Future<List<Dish>> getDishesByCategory(String categoryId) async {
    if (!await connect()) return [];

    try {
      final collection = _db!.collection('dishes');
      final categoryObjectId = _tryParseObjectId(categoryId);
      final query = categoryObjectId == null
          ? {'categoryId': categoryId}
          : {
              'categoryId': {
                r'$in': [categoryId, categoryObjectId],
              },
            };
      final dishes = await collection.find(query).toList();

      _lastError = null;
      _logger.info('Fetched ${dishes.length} dishes for category $categoryId');
      return dishes.map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      _lastError = 'Error fetching dishes for this category. $e';
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
    if (!await connect()) {
      return {'error': _lastError ?? 'Registration failed'};
    }

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
      _lastError = null;
      _logger.info('User registered successfully: $email');
      return userData;
    } catch (e) {
      _lastError = 'Error registering user. $e';
      _logger.severe('Error registering user: $e');
      return {'error': 'Registration failed'};
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    if (!await connect()) {
      return {'error': _lastError ?? 'Login failed'};
    }

    try {
      final collection = _db!.collection('users');
      final user = await collection.findOne(
        where.eq('email', email).and(where.eq('password', password)),
      );

      if (user != null) {
        _lastError = null;
        _logger.info('User logged in successfully: $email');
        return user;
      }
      return {'error': 'Invalid email or password'};
    } catch (e) {
      _lastError = 'Error logging in user. $e';
      _logger.severe('Error logging in user: $e');
      return {'error': 'Login failed'};
    }
  }

  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
  }) async {
    if (!await connect()) return false;

    try {
      final collection = _db!.collection('users');
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      if (updateData.isEmpty) return true;

      var updateModifier = modify;
      updateData.forEach((key, value) {
        updateModifier = updateModifier.set(key, value);
      });

      await collection.updateOne(
        where.id(ObjectId.fromHexString(userId)),
        updateModifier,
      );
      _lastError = null;
      _logger.info('User profile updated: $userId');
      return true;
    } catch (e) {
      _lastError = 'Error updating user profile. $e';
      _logger.severe('Error updating user profile: $e');
      return false;
    }
  }

  static Future<List<Order>> getUserOrders(String userId) async {
    if (!await connect()) return [];

    try {
      final collection = _db!.collection('orders');
      final orders = await collection.find(where.eq('userId', userId)).toList();
      _lastError = null;
      return orders.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      _lastError = 'Error fetching user orders. $e';
      _logger.warning('Error fetching user orders: $e');
      return [];
    }
  }

  static Future<List<Address>> getUserAddresses(String userId) async {
    if (!await connect()) return [];

    try {
      final collection = _db!.collection('addresses');
      final addresses = await collection
          .find(where.eq('userId', userId))
          .toList();
      _lastError = null;
      return addresses.map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      _lastError = 'Error fetching user addresses. $e';
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
    if (!await connect()) return false;

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
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = 'Error adding address. $e';
      _logger.severe('Error adding address: $e');
      return false;
    }
  }

  static Future<bool> setDefaultAddress(String userId, String addressId) async {
    if (!await connect()) return false;

    try {
      final collection = _db!.collection('addresses');

      // Clear default flag for all addresses of this user
      await collection.updateMany(
        where.eq('userId', userId),
        modify.set('isDefault', false),
      );

      // Set the specified address to default
      await collection.updateOne(
        where
            .id(ObjectId.fromHexString(addressId))
            .and(where.eq('userId', userId)),
        modify.set('isDefault', true),
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastError = 'Error setting default address. $e';
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
    if (!await connect()) return false;

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
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = 'Error creating order. $e';
      _logger.severe('Error creating order: $e');
      return false;
    }
  }
}
